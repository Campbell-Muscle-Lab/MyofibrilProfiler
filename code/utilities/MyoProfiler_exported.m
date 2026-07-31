classdef MyoProfiler_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MyoProfilerUIFigure            matlab.ui.Figure
        Menu                           matlab.ui.container.Menu
        LoadImageMenu                  matlab.ui.container.Menu
        NikonMenu                      matlab.ui.container.Menu
        ZeissMenu                      matlab.ui.container.Menu
        StandardFormatsMenu            matlab.ui.container.Menu
        LoadAnalysisMenu               matlab.ui.container.Menu
        ExportAnalysisMenu             matlab.ui.container.Menu
        AnalysisPanelZLine             matlab.ui.container.Panel
        ZLineAnalysisTabGroup          matlab.ui.container.TabGroup
        SarcomereLengthTab             matlab.ui.container.Tab
        SummaryTableZLineSL            matlab.ui.control.Table
        MetricsTab                     matlab.ui.container.Tab
        SummaryTableZLineMetrics       matlab.ui.control.Table
        BinaryTabGroup                 matlab.ui.container.TabGroup
        BinaryTab                      matlab.ui.container.Tab
        AnalysisPanelABand             matlab.ui.container.Panel
        SummaryTableABand              matlab.ui.control.Table
        Sarcomeres                     matlab.ui.control.UIAxes
        SarcomereMean                  matlab.ui.control.UIAxes
        ControlsPanel                  matlab.ui.container.Panel
        ProfilePanel                   matlab.ui.container.Panel
        SecondaryProminenceEditField   matlab.ui.control.NumericEditField
        ABandProminenceEditFieldLabel  matlab.ui.control.Label
        PrimaryProminenceEditField     matlab.ui.control.NumericEditField
        ZLineProminenceEditFieldLabel  matlab.ui.control.Label
        PeakDistancepxEditField        matlab.ui.control.NumericEditField
        PeakDistancepxEditFieldLabel   matlab.ui.control.Label
        CalibrationumpxEditField       matlab.ui.control.NumericEditField
        CalibrationumpxEditFieldLabel  matlab.ui.control.Label
        ROIPanel                       matlab.ui.container.Panel
        WidthpxEditField               matlab.ui.control.NumericEditField
        WidthpxEditFieldLabel          matlab.ui.control.Label
        SelectPointsButton             matlab.ui.control.Button
        ChannelColormapPanel           matlab.ui.container.Panel
        ChannelColorDropDown           matlab.ui.control.DropDown
        LabelingPanel                  matlab.ui.container.Panel
        LabelingDropDown               matlab.ui.control.DropDown
        ProfilerPanel                  matlab.ui.container.Panel
        ProfileIntensityYCoord         matlab.ui.control.UIAxes
        ProfileIntensityXCoord         matlab.ui.control.UIAxes
        ProfileIntensity               matlab.ui.control.UIAxes
        ImageDisplayPanel              matlab.ui.container.Panel
        ImageTabGroup                  matlab.ui.container.TabGroup
        ImageTab                       matlab.ui.container.Tab
        ImageAxes                      matlab.ui.control.UIAxes
    end


    properties (Access = public)
        myofibril_data = []
        shaded_stats
    end

    properties (Access = private)
        Tabs
        BinaryTabs
        ChannelAxes
        BinaryChannelAxes
        ChannelColors
        SplineLine
        BinarySplineLine
        LoadedAnalysis = false
        Patches = []
        StructuralSpline 
    end

    methods (Access = public)

        function ExtractProfiles(app,channel_no)

            im = app.myofibril_data.image{channel_no};
            xs = app.myofibril_data.profile(channel_no).xs;
            ys = app.myofibril_data.profile(channel_no).ys;
            prominence = app.PrimaryProminenceEditField.Value;
            peak_distance = app.PeakDistancepxEditField.Value;
            roi_width = app.WidthpxEditField.Value;
            col = app.ChannelColors(channel_no,:);
            labeling = app.LabelingDropDown.Value;
            calibration = app.CalibrationumpxEditField.Value;


            [prof_x, prof_y, im_profile] = improfile(im, xs, ys);

            x_profile = 1:numel(im_profile);


            if roi_width > 1
                [im_profile_rot,rot_prof_x,rot_prof_y] = quad_image_rotation(im,roi_width,prof_x,prof_y,x_profile);
                x_profile(end) = [];
                prof_x(end) = [];
                prof_y(end) = [];
                im_profile = [];
                im_profile = im_profile_rot;


                app.GeneratePatches(rot_prof_x,rot_prof_y,channel_no);

            end


            switch labeling
                case 'Along'
                    % [pks_z_line, locs_z_line] = findpeaks(-rescale(im_profile), ...
                    %     'MinPeakProminence', prominence * range(rescale(im_profile)), ...
                    %     'MinPeakDistance',peak_distance);
                    flipped_profile = -rescale(im_profile) + 1;
                    [fp_peaks, all_minima,fp_widths] = findpeaks(flipped_profile, ...
                        'MinPeakProminence', prominence * range(flipped_profile), ...
                        'MinPeakDistance',peak_distance);
                    % figure(2)
                    % findpeaks(flipped_profile, ...
                    %     'MinPeakProminence', prominence * range(flipped_profile), ...
                    %     'MinPeakDistance',peak_distance)
                    % figure(2)
                    % findpeaks(-rescale(im_profile), ...
                    %     'MinPeakDistance',peak_distance)
                    % figure(23)
                    % findpeaks(flipped_profile, ...
                    %     'MinPeakProminence', prominence * range(flipped_profile), ...
                    %     'MinPeakDistance',peak_distance,'Annotate','extents')
                    [~,p,~,~] = ttest2(fp_widths(2:2:end),fp_widths(1:2:end))
                    mean(fp_widths(2:2:end))
                    mean(fp_widths(1:2:end))

                    if p > 0.05
                        msg = sprintf('Channel %i profile does not have a distinguishable pattern.',channel_no);
                        f = msgbox(msg,"Warning","warn");
                        plot_profiles(app,prof_x,prof_y,im_profile,col)
                        return;
                    else
                        if (fp_widths(1) >= fp_widths(2)) || (fp_peaks(1) > fp_peaks(2))
                            locs_z_line = all_minima(1:2:end);
                        else
                            locs_z_line = all_minima(2:2:end);
                        end

                    end

                case 'Across'
                    [pks_z_line, locs_z_line] = findpeaks(rescale(im_profile), ...
                        'MinPeakProminence', prominence * range(rescale(im_profile)), ...
                        'MinPeakDistance',peak_distance,'MinPeakHeight',0.1);
                    
            end
            app.myofibril_data.profile(channel_no).locz_z_line = locs_z_line;
            hold(app.ProfileIntensity,'on')
            hold(app.ProfileIntensityXCoord,'on')
            hold(app.ProfileIntensityYCoord,'on')


            plot_profiles(app,prof_x,prof_y,im_profile,col)

            x_limits_horizontal = [prof_x(1) prof_x(end)];
            x_limits_horizontal = sort(x_limits_horizontal,'ascend');
            x_limits_vertical = [prof_y(1) prof_y(end)];
            x_limits_vertical = sort(x_limits_vertical,'ascend');
            xlim(app.ProfileIntensityXCoord,x_limits_horizontal)
            xlim(app.ProfileIntensityYCoord,x_limits_vertical)

            col(4) = 0.7;
            for i = 1 : numel(locs_z_line)
                plot(app.ProfileIntensityXCoord,prof_x(locs_z_line((i)))*ones(1,10),linspace(0,1,10),'LineStyle','--','color',col,'LineWidth',1.7)
                plot(app.ProfileIntensityYCoord,prof_y(locs_z_line((i)))*ones(1,10),linspace(0,1,10),'LineStyle','--','color',col,'LineWidth',1.7)
            end
            col(4) = [];

            app.ExtractSarcomeres(channel_no,im_profile,locs_z_line,prof_x,prof_y,col);

            function plot_profiles(app,prof_x,prof_y,im_profile,col)

                plot3(app.ProfileIntensity,prof_x,prof_y,rescale(im_profile),'color',col,'LineWidth',1.7);
                ang = atan2((prof_y(end) - prof_y(1)), (prof_x(end) - prof_x(1)));
                view(app.ProfileIntensity,[rad2deg(ang),30])
                plot(app.ProfileIntensityXCoord,prof_x,rescale(im_profile),'Color',col,'LineWidth',1.7);
                plot(app.ProfileIntensityYCoord,prof_y,rescale(im_profile),'Color',col,'LineWidth',1.7);
            end

        end

        function ExtractSarcomeres(app,channel_no,im_profile,locs_z_line,prof_x,prof_y,col)

            prominence = app.SecondaryProminenceEditField.Value;
            peak_distance = app.PeakDistancepxEditField.Value;
            calibration = app.CalibrationumpxEditField.Value;
            labeling = app.LabelingDropDown.Value;

            sarcs_to_remove = [];

            no_of_sarcomeres = numel(locs_z_line) - 1;

            for i = 1 : no_of_sarcomeres
                distance = arclength(prof_x(locs_z_line(i):locs_z_line(i+1)),prof_y(locs_z_line(i):locs_z_line(i+1)),'spline');
                sarc_len(i) = calibration*distance;
            end

            if no_of_sarcomeres == 0 && strcmp(labeling,'Across')
                app.ZLineAnalysisTabGroup.SelectedTab = app.MetricsTab;
                app.CalculateZLineMetrics(channel_no,im_profile,locs_z_line,prof_x,prof_y);;
                app.UpdateSummaryTableZlineMetrics(channel_no);
            end


            % for i = 1 : no_of_sarcomeres
            %     profile_indices = locs_z_line(i) : locs_z_line(i+1);
            %     x_coord = prof_x(profile_indices);
            %     y_coord = prof_y(profile_indices);
            %     sarc_profile = im_profile(profile_indices);
            %     sarc_profile = rescale(sarc_profile)
            %     locs_all = [];
            %     locs_m_line = [];
            %
            %     % u_fwhm = [];
            %     try
            %         [~, locs_all] = findpeaks((sarc_profile), ...
            %             'MinPeakDistance',peak_distance, ...
            %             'MinPeakProminence',prominence);
            %         [~,locs_m_line] = max(-sarc_profile(locs_all(1):locs_all(2)));
            %         locs_m_line = locs_m_line + locs_all(1) - 1;
            %     catch
            %         sarcs_to_remove = [sarcs_to_remove;i];
            %         u_fwhm(i) = NaN;
            %         continue
            %     end
            %
            %     u_fwhm_ix(i,1) = find(sarc_profile >= 0.5*sarc_profile(locs_all(1)),1,'first');
            %     u_fwhm_ix(i,2) = find(sarc_profile >= 0.5*sarc_profile(locs_all(2)),1,'last');
            %     u_fwhm(i) = calibration*arclength(x_coord(u_fwhm_ix(i,1):u_fwhm_ix(i,2)),y_coord(u_fwhm_ix(i,1):u_fwhm_ix(i,2)),'spline')
            %
            % end

            sarc_col = return_color_scheme(col,no_of_sarcomeres);

            for i = 1 : no_of_sarcomeres

                mean_sarc_len = mean(sarc_len);
                x_sarc_profile(i,:) = linspace(0,sarc_len(i), 1000);
                profile_indices = locs_z_line(i) : locs_z_line(i+1);
                x_temp = sarc_len(i)*normalize(profile_indices, 'range');
                x_sarc_profile(i,end) = x_temp(end);
                y_sarc_profile(i, :) = interp1(x_temp, im_profile(profile_indices), ...
                    x_sarc_profile(i,:));
                y_sarc_profile(i,:) = normalize(y_sarc_profile(i,:),'range');
                hold(app.Sarcomeres,'on')

                switch labeling
                    case 'Along'
                        locs_all = [];
                        locs_m_line = [];
                        % fwhm = [];
                        try
                            [~, locs_all] = findpeaks(y_sarc_profile(i,:), ...
                                'MinPeakDistance',peak_distance, ...
                                'MinPeakProminence',prominence);
                            [~,locs_m_line] = max(-y_sarc_profile(i,locs_all(1):locs_all(2)));
                            locs_m_line = locs_m_line + locs_all(1) - 1;
                            x_sarc_profile(i,:) = x_sarc_profile(i,:)  - x_sarc_profile(i,locs_m_line);
                            fwhm_ix(i,1) = find(y_sarc_profile(i,:) >= 0.5*(y_sarc_profile(i,locs_all(1)) + y_sarc_profile(i,1)),1,'first');
                            fwhm_ix(i,2) = find(y_sarc_profile(i,:) >= 0.5*(y_sarc_profile(i,locs_all(2)) + y_sarc_profile(i,end)),1,'last');
                            fwhm(i) = x_sarc_profile(i,fwhm_ix(i,2)) - x_sarc_profile(i,fwhm_ix(i,1));


                            hold(app.Sarcomeres,'on')

                            plot(app.Sarcomeres,x_sarc_profile(i,:),y_sarc_profile(i,:),'Color',sarc_col(i,:),'LineWidth',1.7)
                            scatter(app.Sarcomeres,x_sarc_profile(i,locs_m_line),y_sarc_profile(i,locs_m_line),80,'d','MarkerEdgeColor',[0 0 0],...
                                'MarkerFaceColor',[1 0 1],...
                                'MarkerFaceAlpha',0.5)
                            scatter(app.Sarcomeres,x_sarc_profile(i,locs_all),y_sarc_profile(i,locs_all),80,'d','MarkerEdgeColor',[0 0 0],...
                                'MarkerFaceColor',[1 0 0],...
                                'MarkerFaceAlpha',0.5)
                        catch
                            sarcs_to_remove = [sarcs_to_remove;i];
                            fwhm(i) = NaN;
                            if i ~= no_of_sarcomeres
                                continue
                            end
                        end


                        if i == no_of_sarcomeres

                            if ~isempty(sarcs_to_remove)
                                y_sarc_profile(sarcs_to_remove,:) = [];
                                x_sarc_profile(sarcs_to_remove,:) = [];
                                sarc_len(sarcs_to_remove) = [];
                                fwhm(sarcs_to_remove) = [];
                            end

                            if no_of_sarcomeres > 0
                                mean_sarc_profile = mean(y_sarc_profile,1);

                                x_sarc_profile_mean = mean(x_sarc_profile,1);
                                hold(app.SarcomereMean,"on")
                                if size(y_sarc_profile,1) == 1
                                    plot(app.SarcomereMean, x_sarc_profile_mean,y_sarc_profile,'-','LineWidth',1.7,'Color',col)
                                else
                                    shadedErrorBar2(x_sarc_profile_mean, y_sarc_profile, {@mean, @std},{'-','LineWidth',1.7,'Color',col},1,app.SarcomereMean);
                                end

                                xlim(app.Sarcomeres,[-0.51*mean_sarc_len 0.51*mean_sarc_len])
                                xlim(app.SarcomereMean,[-0.51*mean_sarc_len 0.51*mean_sarc_len])


                                app.myofibril_data.profile(channel_no).intensity = im_profile;
                                app.myofibril_data.profile(channel_no).sarcomere_intensities = y_sarc_profile;
                                app.myofibril_data.profile(channel_no).sarcomere_location = x_sarc_profile;
                                app.myofibril_data.profile(channel_no).mean_sarcomere_location = mean(x_sarc_profile,1);
                                app.myofibril_data.profile(channel_no).mean_sarcomere_profile = mean_sarc_profile;
                                app.myofibril_data.profile(channel_no).std_sarcomere_profile = std(y_sarc_profile,0,1);
                                app.myofibril_data.profile(channel_no).sem_sarcomere_profile = std(y_sarc_profile,0,1)./sqrt(length(y_sarc_profile));
                                app.myofibril_data.profile(channel_no).sarcomere_lengths = sarc_len;
                                app.myofibril_data.profile(channel_no).fwhm = fwhm;
                                app.myofibril_data.calibration = calibration;

                                no_of_sarcomeres = numel(sarc_len);
                                if no_of_sarcomeres > 0
                                    app.UpdateSummaryTableABand(channel_no,no_of_sarcomeres,sarc_col);
                                end
                            end
                        end




                    case 'Across'
                        % 
                        % adj_z_profile = im_profile(locs_z_line(i):locs_z_line(i+1));
                        % [pt,lc] = max(-adj_z_profile)
                        % 
                        % figure(99)
                        % hold on
                        % 
                        % plot(adj_z_profile)
                        % plot(lc,adj_z_profile(lc),'o')

                        % [~, locs_all] = findpeaks(y_sarc_profile(i,:), ...
                        %     'MinPeakDistance',peak_distance, ...
                        %     'MinPeakProminence',prominence);
                        % [~,locs_m_line] = max(-y_sarc_profile(i,locs_all(1):locs_all(2)));
                        % locs_m_line = locs_m_line + locs_all(1) - 1;
                        % x_sarc_profile(i,:) = x_sarc_profile(i,:)  - x_sarc_profile(i,locs_m_line);
                        % fwhm_ix(i,1) = find(y_sarc_profile(i,:) >= 0.5*(y_sarc_profile(i,locs_all(1)) + y_sarc_profile(i,1)),1,'first');
                        % fwhm_ix(i,2) = find(y_sarc_profile(i,:) >= 0.5*(y_sarc_profile(i,locs_all(2)) + y_sarc_profile(i,end)),1,'last');
                        % fwhm(i) = x_sarc_profile(i,fwhm_ix(i,2)) - x_sarc_profile(i,fwhm_ix(i,1));

                        if i == no_of_sarcomeres
                            app.myofibril_data.profile(channel_no).sarcomere_lengths = sarc_len;
                            app.CalculateZLineMetrics(channel_no,im_profile,locs_z_line,prof_x,prof_y);
                            app.UpdateSummaryTableZlineMetrics(channel_no);
                            app.UpdateSummaryTableZlineSL(channel_no,no_of_sarcomeres);
                            mean_sarc_profile = mean(y_sarc_profile,1);
                            app.myofibril_data.profile(channel_no).intensity = im_profile;
                            app.myofibril_data.profile(channel_no).sarcomere_intensities = y_sarc_profile;
                            app.myofibril_data.profile(channel_no).sarcomere_location = x_sarc_profile;
                            app.myofibril_data.profile(channel_no).mean_sarcomere_location = mean(x_sarc_profile,1);
                            app.myofibril_data.profile(channel_no).mean_sarcomere_profile = mean_sarc_profile;
                            app.myofibril_data.profile(channel_no).std_sarcomere_profile = std(y_sarc_profile,0,1);
                            app.myofibril_data.profile(channel_no).sem_sarcomere_profile = std(y_sarc_profile,0,1)./sqrt(length(y_sarc_profile));
                            app.myofibril_data.profile(channel_no).sarcomere_lengths = sarc_len;
                            app.myofibril_data.calibration = calibration;
                        end
                end

            end
        end

        function RefreshDisplay(app)

            ax = {'ProfileIntensity','Sarcomeres','SarcomereMean','ProfileIntensityXCoord','ProfileIntensityYCoord'};

            for i = 1:numel(ax)
                cla(app.(ax{i}))
            end

            app.SummaryTableABand.Data = [];
            app.SummaryTableZLineMetrics.Data = [];
            app.SummaryTableZLineSL.Data = [];


        end

        function ColorScheme(app)

            app.ChannelColors = [];

            selected_scheme = app.ChannelColorDropDown.Value;

            num_of_channels = size(app.Tabs,2)-1;

            switch selected_scheme
                case 'Em. Wavelength'
                    for i = 1 : num_of_channels
                        app.ChannelColors(i,:) = wavelength2color(app.myofibril_data.em_wavelengths(i));
                    end
                case 'Parula'
                    app.ChannelColors = parula(num_of_channels);
            end

        end

        function PseudoColoring(app)

            raw_images = app.myofibril_data.image;
            XLim = app.ChannelAxes{1}.XLim;
            YLim = app.ChannelAxes{1}.YLim;

            for i = 1 : numel(raw_images)

                r_channel = app.ChannelColors(i,1) * raw_images{i,1};
                g_channel = app.ChannelColors(i,2) * raw_images{i,1};
                b_channel = app.ChannelColors(i,3) * raw_images{i,1};
                pseudo_color_images{i,1} = cat(3,r_channel,g_channel,b_channel);
                pseudo_color_images{i,1} = rescale(pseudo_color_images{i,1});

                if i == 1
                    fused_image = pseudo_color_images{i,1};
                else
                    fused_image = imfuse(fused_image,pseudo_color_images{i,1},'blend', 'Scaling', 'joint');
                end
            end
            app.myofibril_data.pseudo_color_images = pseudo_color_images;
            app.myofibril_data.fused_image = fused_image;
            center_image_with_preserved_aspect_ratio(app.myofibril_data.fused_image,app.ChannelAxes{end})
            app.ChannelAxes{end}.XLim = XLim;
            app.ChannelAxes{end}.YLim = YLim;


        end


        function UpdateSummaryTableABand(app,channel_no,no_of_sarcomeres,sarc_col)

            for i = 1 : no_of_sarcomeres
                st.channel(i,:) = channel_no;
                st.band_no(i,:) = i;
                st.color{i,:} = '';
            end
            st.sarcomere_lengths = app.myofibril_data.profile(channel_no).sarcomere_lengths';
            st.fwhm_um = app.myofibril_data.profile(channel_no).fwhm';

            if numel(st.sarcomere_lengths) ~= numel(st.fwhm_um)
                st.fwhm_um(end+1:numel(st.sarcomere_lengths),1) = NaN;
            end


            app.SummaryTableABand.Data = [app.SummaryTableABand.Data; struct2table(st)];

            if channel_no > 1
                starting_ix = size(app.SummaryTableABand.Data,1) - no_of_sarcomeres;
            else
                starting_ix = 0;
            end

            for i = 1 : no_of_sarcomeres
                s = uistyle("BackgroundColor",sarc_col(i,:));
                addStyle(app.SummaryTableABand,s,"cell",[starting_ix+i 3])
            end

        end


        function GeneratePatches(app,rot_prof_x,rot_prof_y,channel_no)
            app.Patches{channel_no} = patch(app.ChannelAxes{channel_no},[rot_prof_x(:,1); flip(rot_prof_x(:,2))], ...
                [rot_prof_y(:,1); flip(rot_prof_y(:,2))], ...
                [1 0 1]*0.8, 'EdgeColor','none', ...
                'FaceAlpha',0.25);
        end

        function BinarizeImages(app)

            im = app.myofibril_data.image;
            sz = size(im);
            im_ax = app.ImageAxes;
            app.BinaryTabs = [];
            app.BinaryChannelAxes = [];
            delete(app.BinaryTabGroup.Children)


            for i = 1:sz(1)
                app.BinaryTabs{i} = uitab(app.BinaryTabGroup,'Title',['Binary: Channel ' num2str(i)]);
                app.BinaryChannelAxes{i} = copyobj(im_ax,app.BinaryTabs{i});
                app.BinaryChannelAxes{i}.Visible = 'on';

                app.myofibril_data.binary_image{i,1} = imbinarize(app.myofibril_data.image{i,1},'adaptive',Sensitivity=0.35);
                app.myofibril_data.binary_image{i,1} = bwareaopen(app.myofibril_data.binary_image{i,1}, 20);
                app.myofibril_data.binary_image{i,1} = imfill(app.myofibril_data.binary_image{i,1}, 'holes');

                center_image_with_preserved_aspect_ratio(app.myofibril_data.binary_image{i,1},app.BinaryChannelAxes{i})
            end



        end

        function CalculateZLineMetrics(app,channel_no,im_profile,locs_z_line,prof_x,prof_y)

                peak_distance = app.PeakDistancepxEditField.Value;
                calibration = app.CalibrationumpxEditField.Value;
                num_of_bin_tabs = size(app.BinaryChannelAxes,2);
                num_of_line_tabs = 0.5*num_of_bin_tabs;
                binary_image = app.myofibril_data.binary_image{channel_no,1};
                x = app.myofibril_data.profile(1).xs;
                y = app.myofibril_data.profile(1).ys;
                app.myofibril_data.profile(channel_no).fwhm = [];
                app.myofibril_data.profile(channel_no).tortuosity = [];
                app.myofibril_data.profile(channel_no).structural_splines = [];


                [lab_im,total_number_of_blobs] = bwlabel(binary_image);

                bin_im_stats = regionprops(binary_image, 'Centroid','Area','ConvexHull', ...
                    'ConvexArea','PixelList','Orientation','Image','BoundaryCoordinates');

                % B = bwboundaries(binary_image)

                hold(app.BinaryChannelAxes{(channel_no)},"on");

                x_r = round(x);
                y_r = round(y);

                valid = x_r >= 1 & x_r <= size(binary_image,2) & ...
                    y_r >= 1 & y_r <= size(binary_image,1);
                
                x_r = x_r(valid);
                y_r = y_r(valid);

                ix = sub2ind(size(binary_image), y_r, x_r);

                blob_ids = unique(lab_im(ix));

                blob_ids(blob_ids == 0) = [];

                % for i = 1 : numel(blob_ids)
                %         xy_or = bin_im_stats(blob_ids(i)).BoundaryCoordinates;
                %         plot(app.BinaryChannelAxes{(channel_no)},xy_or(:,1),xy_or(:,2),'ro')
                % end
                
                blobs_in_roi_stats = bin_im_stats(blob_ids);
                number_of_blobs_across = size(blobs_in_roi_stats,1);
                final_blob_ids = [];
                for i = 1 : number_of_blobs_across
                    or = bin_im_stats(blob_ids(i)).Orientation;
                    center = bin_im_stats(blob_ids(i)).Centroid;
                    spline_is_crossing_blob = 1;
                    blob_ids_u = blob_ids(i);
                    blob_conn = 1;
                    while spline_is_crossing_blob
                        xy_or = [];
                        x = [];
                        y = [];
                        for k = 1 : numel(blob_ids_u)
                            xy_or = [];
                            xy_or = bin_im_stats(blob_ids_u(k)).PixelList;
                            x = [x;xy_or(:,1)];
                            y = [y;xy_or(:,2)];
                        end
                        
                        [x_new,y_new] = rotate_around(x,y,center,or);
              
                        sp = csaps(x_new,y_new,0.1);

                        u = sort(x_new,'ascend');
                        pixel_pad = 50;
                        u_padded = linspace(u(1)-pixel_pad,u(end)+pixel_pad,1000);

                        extrap_pp = fnxtr(sp, 1);
                        v_padded = ppval(extrap_pp,u_padded);

                        [x,y] = rotate_around(u_padded,v_padded,center,-or);
                        

                        x_r = round(x);
                        y_r = round(y);

                        valid = x_r >= 1 & x_r <= size(binary_image,2) & ...
                            y_r >= 1 & y_r <= size(binary_image,1);

                        x_r = x_r(valid);
                        y_r = y_r(valid);

                        ix = sub2ind(size(binary_image), y_r, x_r);

                        blob_ids_u = unique(lab_im(ix));

                        blob_ids_u(blob_ids_u == 0) = [];

                        if numel(blob_ids_u) > blob_conn
                            blob_conn = numel(blob_ids_u);
                        else
                            spline_is_crossing_blob = 0;
                            u = linspace(u(1),u(end),1000);
                            v = ppval(sp,u);
                            [x_current,y_current] = rotate_around(u,v,center,-or);
                            app.myofibril_data.profile(channel_no).structural_splines{i} = [x_current;y_current]';
                            uistack(app.BinarySplineLine{channel_no})
                            final_blob_ids = [final_blob_ids blob_ids_u];
                            blob_id_track{i} = blob_ids_u;
                        end
                    end
                end
                

                blob_col_map = ones(total_number_of_blobs,3);
                col_map = lines(number_of_blobs_across);

                for i = 1 : number_of_blobs_across
                    
                    ix = nonzeros(blob_id_track{i});
                    for k = 1 : numel(ix)
                        blob_col_map(ix(k),:) = col_map(i,:);
                    end

                end


                col_im = label2rgb(lab_im,blob_col_map,[0 0 0]);
                x_lim = app.BinaryChannelAxes{channel_no}.XLim;
                y_lim = app.BinaryChannelAxes{channel_no}.YLim;

                center_image_with_preserved_aspect_ratio(col_im,app.BinaryChannelAxes{channel_no})
                app.BinaryChannelAxes{channel_no}.XLim = x_lim;
                app.BinaryChannelAxes{channel_no}.YLim = y_lim;

                app.myofibril_data.binary_roi{channel_no} = copyobj(app.myofibril_data.roi{channel_no}, app.BinaryChannelAxes{channel_no});
                addlistener(app.myofibril_data.binary_roi{channel_no},"ROIMoved",@(src,evt) UpdateROIProfile(app,evt));
                app.BinarySplineLine{channel_no} = copyobj(app.SplineLine{channel_no}, app.BinaryChannelAxes{channel_no});
                num_str_sp = numel(app.myofibril_data.profile(channel_no).structural_splines);

                for i = 1 : num_str_sp


                    x_s = app.myofibril_data.profile(channel_no).structural_splines{i}(:,1);
                    y_s = app.myofibril_data.profile(channel_no).structural_splines{i}(:,2);
                    plot(app.BinaryChannelAxes{channel_no},x_s,y_s,'w','LineWidth',1.7)

                    x_endpoints = linspace(x_s(1),x_s(end),20);
                    y_endpoints = linspace(y_s(1),y_s(end),20);
                    plot(app.BinaryChannelAxes{channel_no},x_endpoints,y_endpoints, ...
                    'LineWidth',1.7, ...
                    'LineStyle','--', ...
                    'Color',[0.7 0.7 0.7])

                    for k = 1 : numel(x_s)-1
                        distances(k) = sqrt((x_s(k+1)-x_s(k)) ^2 + (y_s(k+1)-y_s(k)) ^ 2);
                    end
                    spline_length(i,1) = sum(distances);
                    end_point_distance(i,1) = sqrt((x_s(end)-x_s(1))^2 + (y_s(end)-y_s(1))^2);

                end

                [~,locs_z_line_base] = findpeaks(rescale(-im_profile), ...
                    "MinPeakDistance",peak_distance, ...
                    "MinPeakHeight",0.8);

                % figure(22)
                % findpeaks(rescale(-im_profile), ...
                %     "MinPeakDistance",peak_distance, ...
                %     "MinPeakHeight",0.8)

                for i = 1 : numel(locs_z_line)
                    
                    
                    if ~any(locs_z_line_base <= locs_z_line(i))
                        [~,adj_base_lines(1)] = max(rescale(-im_profile(1:locs_z_line(i))));
                    else
                        adj_base_lines(1) = locs_z_line_base(find(locs_z_line_base <= locs_z_line(i), 1, 'last'));
                    end

                    if ~any(locs_z_line_base >= locs_z_line(i))
                        indices = locs_z_line(i):numel(im_profile);
                        [~,t_ix] = max(rescale(-im_profile(indices)));
                        adj_base_lines(2) = indices(t_ix);
                    else
                        adj_base_lines(2) = locs_z_line_base(find(locs_z_line_base >= locs_z_line(i), 1, 'first'));
                    end



                    
                    x_temp = adj_base_lines(1):adj_base_lines(2);
                    x_coord = prof_x(x_temp);
                    y_coord = prof_y(x_temp);
                    x_profile(i,:) = linspace(x_coord(1),x_coord(end),1000);
                    yy_profile(i,:) = linspace(y_coord(1),y_coord(end),1000);


                    z_profile = []
                    z_profile = im_profile(adj_base_lines(1):adj_base_lines(2))
                    utku_profile = interp1(x_coord, ...
                        im_profile(adj_base_lines(1):adj_base_lines(2)), ...
                        x_profile(i,:));
                    utku_profile_2 = interp1(y_coord, ...
                        im_profile(adj_base_lines(1):adj_base_lines(2)), ...
                        yy_profile(i,:));

                    fwhm_ix(i,1) = find(z_profile >= 0.5*(max(z_profile) + z_profile(1)),1,'first')
                    fwhm_ix(i,2) = find(z_profile >= 0.5*(max(z_profile) + z_profile(end)),1,'last')
                    fwhm(i) = calibration*arclength(x_coord(fwhm_ix(i,1):fwhm_ix(i,2)),y_coord(fwhm_ix(i,1):fwhm_ix(i,2)),'spline')




                    % for i = 1 : no_of_sarcomeres
                    %     profile_indices = locs_z_line(i) : locs_z_line(i+1);
                    %     x_coord = prof_x(profile_indices);
                    %     y_coord = prof_y(profile_indices);
                    %     sarc_profile = im_profile(profile_indices);
                    %     sarc_profile = rescale(sarc_profile)
                    %     locs_all = [];
                    %     locs_m_line = [];
                    %
                    %     % u_fwhm = [];
                    %     try
                    %         [~, locs_all] = findpeaks((sarc_profile), ...
                    %             'MinPeakDistance',peak_distance, ...
                    %             'MinPeakProminence',prominence);
                    %         [~,locs_m_line] = max(-sarc_profile(locs_all(1):locs_all(2)));
                    %         locs_m_line = locs_m_line + locs_all(1) - 1;
                    %     catch
                    %         sarcs_to_remove = [sarcs_to_remove;i];
                    %         u_fwhm(i) = NaN;
                    %         continue
                    %     end
                    %
                    %     u_fwhm_ix(i,1) = find(sarc_profile >= 0.5*sarc_profile(locs_all(1)),1,'first');
                    %     u_fwhm_ix(i,2) = find(sarc_profile >= 0.5*sarc_profile(locs_all(2)),1,'last');
                    %     u_fwhm(i) = calibration*arclength(x_coord(u_fwhm_ix(i,1):u_fwhm_ix(i,2)),y_coord(u_fwhm_ix(i,1):u_fwhm_ix(i,2)),'spline')
                    %
                    % end

                    % figure(111)
                    % clf
                    % plot(z_profile)
                    % hold on
                    % plot(fwhm_ix(i,1),z_profile(fwhm_ix(i,1)),'ro')
                    % plot(fwhm_ix(i,2),z_profile(fwhm_ix(i,2)),'ro')
                    

                    % 
                    % y_sarc_profile(i, :) = interp1(x_temp, im_profile(profile_indices), ...
                    %     x_sarc_profile(i,:));



                    % 
                    % 
                    % mean_sarc_len = mean(sarc_len);
                    % x_sarc_profile(i,:) = linspace(0,sarc_len(i), 1000);
                    % profile_indices = locs_z_line(i) : locs_z_line(i+1);
                    % x_temp = sarc_len(i)*normalize(profile_indices, 'range');
                    % x_sarc_profile(i,end) = x_temp(end);
                    % y_sarc_profile(i, :) = interp1(x_temp, im_profile(profile_indices), ...
                    %     x_sarc_profile(i,:));
                    % y_sarc_profile(i,:) = normalize(y_sarc_profile(i,:),'range');
                    % hold(app.Sarcomeres,'on')

                    % [~,locs_m_line] = max(-y_sarc_profile(i,locs_all(1):locs_all(2)));
                    % locs_m_line = locs_m_line + locs_all(1) - 1;
                    % x_sarc_profile(i,:) = x_sarc_profile(i,:)  - x_sarc_profile(i,locs_m_line);





                end
                app.myofibril_data.profile(channel_no).fwhm = fwhm;
                tortuosity = spline_length./end_point_distance;
                app.myofibril_data.profile(channel_no).tortuosity = tortuosity;

            function [x_rot,y_rot] = rotate_around(x,y,center,angle)

                if size(x,1) ~= 1
                    x = x';
                end
                if size(y,1) ~= 1
                    y = y';
                end
                x_rel = x - center(1);
                y_rel = y - center(2);

                R = [cosd(angle) -sind(angle); sind(angle) cosd(angle)];
                rotated_coords = R * [x_rel ;y_rel];


                x_rot = rotated_coords(1,:) + center(1);
                y_rot = rotated_coords(2,:) + center(2);

            end



                


                % mask = poly2mask(x,y,size(binary_image,1),size(binary_image,2));
                % binary_image(~mask) = 0;
                % stats_mask = regionprops(mask,'BoundingBox');
                % cropped_binary_image = [];
                % cropped_binary_image = imcrop(binary_image,stats_mask.BoundingBox);
                % bin_sk = bwskel(binary_image, 'MinBranchLength', 10);
                % conn_comp = bwconncomp(bin_sk);
                % % stats = regionprops(conn_comp, 'Area', 'PixelIdxList');
                % [labeled_im,number_of_blobs]= bwlabel(bin_sk);
                % stats_sk = regionprops(labeled_im, 'Area', 'PixelIdxList');

                % col_map = return_matplotlib_default_colors;
                % col_bin_sk = cat(3,bin_sk * col_map(1,1), bin_sk * col_map(1,2), bin_sk * col_map(1,3));
                % cla(app.BinaryChannelAxes{lines_tabs(channel_no)})
                % B = imoverlay(app.myofibril_data.binary_image{channel_no,1},bin_sk,col_map(1,:));
                % center_image_with_preserved_aspect_ratio(B,app.BinaryChannelAxes{(channel_no)});
                % 
                % for j = 1 : number_of_blobs
                % 
                %     single_stripe = ismember(labeled_im,j);
                %     [stripe_rows,stripe_cols] = find(single_stripe);
                %     distances = [];
                %     for k = 1 : numel(stripe_rows)-1        
                %         distances(k) = sqrt((stripe_rows(k+1)-stripe_rows(k)) ^2 + (stripe_cols(k+1)-stripe_cols(k)) ^ 2);
                %     end
                %     stripe_length(j,1) = sum(distances);
                % 
                %     end_points = bwmorph(single_stripe, 'endpoints');
                %     [x_end, y_end] = find(end_points);
                %     end_point_distance(j,1) = sqrt((x_end(2)-x_end(1))^2 + (y_end(2)-y_end(1))^2);
                %     hold(app.BinaryChannelAxes{(channel_no)},'on')
                %     plot(app.BinaryChannelAxes{(channel_no)},y_end,x_end, 'color',col_map(2,:))
                %     % figure(99)
                %     % imshow(single_stripe)
                % 
                % end
                % 
                % % [labeledImage, numberOfBlobs] = bwlabel(bin_sk);
                % % measurements = regionprops(labeledImage, 'Area', 'Centroid');
                % % figure(99)
                % % imshow(bin_sk)
                % % imshow(labeledImage)
                % 
                % 


        end

        function UpdateSummaryTableZlineMetrics(app,channel_no)
            no_of_stripes = numel(app.myofibril_data.profile(channel_no).tortuosity);
            for i = 1 : no_of_stripes
                st.channel(i,:) = channel_no;
                st.line_no(i,:) = i;
            end
            st.tortuosity = app.myofibril_data.profile(channel_no).tortuosity
            st.fwhm_um = app.myofibril_data.profile(channel_no).fwhm'
            
            if numel(st.fwhm_um) ~= numel(st.tortuosity)
                st.fwhm_um(end+1) = NaN
            end
            app.SummaryTableZLineMetrics.Data = [app.SummaryTableZLineMetrics.Data; struct2table(st)];
        end

        function UpdateSummaryTableZlineSL(app,channel_no,no_of_sarcomeres)
            for i = 1 : no_of_sarcomeres
                st.channel(i,:) = channel_no;
                st.profile_no(i,:) = i;
            end
            st.sarcomere_length_um = app.myofibril_data.profile(channel_no).sarcomere_lengths';

            app.SummaryTableZLineSL.Data = [app.SummaryTableZLineSL.Data; struct2table(st)];

        end
        
        function UpdateROIProfile(app,evt)
            label = app.LabelingDropDown.Value;
            x_upt = evt.CurrentPosition(:,1);
            y_upt = evt.CurrentPosition(:,2);
            cs_upt = spline(x_upt, y_upt);
            xs_upt = linspace(x_upt(1), x_upt(end), 1000);
            ys_upt = ppval(cs_upt, xs_upt);
            app.myofibril_data.profile(1).xs = linspace(x_upt(1), x_upt(end), 1000);
            app.myofibril_data.profile(1).ys = ppval(cs_upt, app.myofibril_data.profile(1).xs);

            for spline_count = 1 : size(app.SplineLine,2)
                app.SplineLine{spline_count}.XData = app.myofibril_data.profile(1).xs;
                app.SplineLine{spline_count}.YData = app.myofibril_data.profile(1).ys;
                app.myofibril_data.roi{spline_count}.Position(:,1) = x_upt;
                app.myofibril_data.roi{spline_count}.Position(:,2) = y_upt;
            end

            switch label
                case 'Across'
                    for spline_count = 1 : size(app.BinarySplineLine,2)
                        app.BinarySplineLine{spline_count}.XData = app.myofibril_data.profile(1).xs;
                        app.BinarySplineLine{spline_count}.YData = app.myofibril_data.profile(1).ys;
                        app.myofibril_data.binary_roi{spline_count}.Position(:,1) = x_upt;
                        app.myofibril_data.binary_roi{spline_count}.Position(:,2) = y_upt;
                    end
            end

            app.RefreshDisplay;
            if ~isempty(app.Patches)
                for patch_no = 1 : size(app.Tabs,2)
                    app.Patches{patch_no}.FaceAlpha = 0;
                end
            end
            for ch_no = 1 : size(app.Tabs,2)-1
                app.myofibril_data.profile(ch_no).xs = app.myofibril_data.profile(1).xs;
                app.myofibril_data.profile(ch_no).ys = app.myofibril_data.profile(1).ys;
                app.ExtractProfiles(ch_no)
            end
        end
        
        
        function LoadMicroscopeFormats(app,scope,scope_ext)
            f = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file_string,path_string]=uigetfile2( ...
                {scope_ext,scope}, ...
                'Select Image File');
            delete(f)

            if (path_string~=0)
                app.myofibril_data = [];
                app.myofibril_data.image_file_string = fullfile(path_string,file_string);
                im_ax = app.ImageAxes;
                app.Tabs = [];
                app.ChannelAxes = [];
                labeling = app.LabelingDropDown.Value;
                app.myofibril_data.image_file = bfopen(app.myofibril_data.image_file_string);
                app.myofibril_data.meta_file = app.myofibril_data.image_file{1,2};
                h = app.myofibril_data.meta_file;
                im = app.myofibril_data.image_file;
                im = im{1,1}
                im(:,2) = [];
                app.myofibril_data.image = im;
                sz = size(im);
                delete(app.ImageTabGroup.Children)
                tab_no = 1;
                brightfield_im = 0;


                switch scope

                    case 'ND2'
                        app.CalibrationumpxEditField.Value = h.get('Global dCalibration');
                        for i = 1:sz(1)
                                w_text = sprintf('Global CSU-W1, FilterChanger(EM) #%i',i);
                                w_text = h.get(w_text);
                                if contains(w_text,'(Empty)')
                                    brightfield_im = i;
                                else
                                em_wavelength = str2double(extractBetween(w_text,"(","/"));
                                app.myofibril_data.em_wavelengths(tab_no) = em_wavelength;
                                app.Tabs{tab_no} = uitab(app.ImageTabGroup,'Title',['Channel ' num2str(tab_no)]);
                                app.ChannelAxes{tab_no} = copyobj(im_ax,app.Tabs{tab_no});
                                app.ChannelAxes{tab_no}.Visible = 'on';
                                center_image_with_preserved_aspect_ratio(app.myofibril_data.image{i,1},app.ChannelAxes{tab_no})
                                % app.myofibril_data.pseudo_color_images{tab_no,1} = app.myofibril_data.image{i,1};
                                tab_no = tab_no + 1;
                                end
                        end
                    case 'CZI'
                        app.CalibrationumpxEditField.Value = str2double(h.get('Global Scaling|Distance|Value #1'))*1e6;
                        for i = 1:sz(1)
                                if sz(1) > 1
                                    w_text = sprintf('Global DisplaySetting|Channel|DyeMaxEmission #%i',i);
                                    fluor_check_text = sprintf('Global Information|Image|Channel|IlluminationType #%i',i);
                                else
                                    w_text = sprintf('Global DisplaySetting|Channel|DyeMaxEmission');
                                    fluor_check_text = sprintf('Global Information|Image|Channel|IlluminationType');
                                end
                                w_text = h.get(w_text);
                                fluor_check_text = h.get(fluor_check_text);
                                
                                if contains(fluor_check_text,'Transmitted') || contains(fluor_check_text,'Brightfield')
                                    brightfield_im = i;
                                else
                                em_wavelength = str2double(w_text);
                                app.myofibril_data.em_wavelengths(tab_no) = em_wavelength;
                                app.Tabs{tab_no} = uitab(app.ImageTabGroup,'Title',['Channel ' num2str(tab_no)]);
                                app.ChannelAxes{tab_no} = copyobj(im_ax,app.Tabs{tab_no});
                                app.ChannelAxes{tab_no}.Visible = 'on';
                                center_image_with_preserved_aspect_ratio(app.myofibril_data.image{i,1},app.ChannelAxes{tab_no})
                                tab_no = tab_no + 1;
                                end
                        end
                end
                if brightfield_im
                    app.myofibril_data.image(brightfield_im) = [];
                end
                app.Tabs{end+1} = uitab(app.ImageTabGroup,'Title','Merged ');
                app.ChannelAxes{end+1} = copyobj(im_ax,app.Tabs{end});
                app.ChannelAxes{end}.Visible = 'on';
                app.ColorScheme;
                app.PseudoColoring
                app.RefreshDisplay
                switch labeling
                    case 'Across'
                        app.BinarizeImages;
                end
            end
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            addpath(genpath('utilities'))
            movegui(app.MyoProfilerUIFigure,'center')
            colormap(app.ImageAxes, 'gray');
        end

        % Menu selected function: NikonMenu
        function NikonImageSelected(app, event)
            scope = 'ND2';
            scope_ext= '*.nd2';
            LoadMicroscopeFormats(app,scope,scope_ext);         
        end

        % Menu selected function: ZeissMenu
        function ZeissMenuSelected(app, event)
            scope = 'CZI';
            scope_ext= '*.czi';
            LoadMicroscopeFormats(app,scope,scope_ext);    
        end

        % Menu selected function: StandardFormatsMenu
        function StandardFormatsImageSelected(app, event)
            prompt = {'Total Number of Channels:','Emission Wavelengths (nm):'};
            dlgtitle = 'Standard Formats Channel Input';
            fieldsize = [1 65; 1 65];
            definput = {'',''};
            user_input = inputdlg(prompt,dlgtitle,fieldsize,definput);
            labeling = app.LabelingDropDown.Value;

            if ~isempty(user_input)
                app.myofibril_data = [];
                total_number_of_channels = str2double(user_input{1});
                em_wavelengths = user_input{2};
                em_wavelengths = split(em_wavelengths,",");
                em_wavelengths = str2double(em_wavelengths)';
                if isnan(em_wavelengths)
                    app.ChannelColorDropDown.Value = 'Parula';
                else
                    app.myofibril_data.em_wavelengths = em_wavelengths;
                end

                for loaded_files = 1 : total_number_of_channels
                    f = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);
                    dialog_text = sprintf('Select Image File for Channel %i',loaded_files);
                    [file_string,path_string]=uigetfile2( ...
                        {'*.tif','TIF';'*.tiff','TIFF';'*.png','PNG'}, ...
                        dialog_text);
                    delete(f)
                    if path_string~=0
                        app.myofibril_data.image_file_string{loaded_files} = fullfile(path_string,file_string);
                        app.myofibril_data.image{loaded_files,1} = imread(app.myofibril_data.image_file_string{loaded_files});
                        if (ndims(app.myofibril_data.image{loaded_files,1})==3)
                            app.myofibril_data.image{loaded_files,1} = rgb2gray(app.myofibril_data.image{loaded_files,1});
                        end
                    end
                end

                if isfield(app.myofibril_data,'image_file_string')

                    im_ax = app.ImageAxes;
                    app.Tabs = [];
                    app.ChannelAxes = [];
                    delete(app.ImageTabGroup.Children)
                    for i = 1:numel(app.myofibril_data.image)
                        app.Tabs{i} = uitab(app.ImageTabGroup,'Title',['Channel ' num2str(i)]);
                        app.ChannelAxes{i} = copyobj(im_ax,app.Tabs{i});
                        app.ChannelAxes{i}.Visible = 'on';
                        center_image_with_preserved_aspect_ratio(app.myofibril_data.image{i},app.ChannelAxes{i})
                        % app.myofibril_data.pseudo_color_images{i,1} = app.myofibril_data.image{i};
                    end
                    app.Tabs{end+1} = uitab(app.ImageTabGroup,'Title','Merged ');
                    app.ChannelAxes{end+1} = copyobj(im_ax,app.Tabs{end});
                    app.ChannelAxes{end}.Visible = 'on';
                    app.ColorScheme;
                    app.PseudoColoring;
                    app.RefreshDisplay;
                    switch labeling
                        case 'Across'
                            app.BinarizeImages;
                    end
                end
            end
        end

        % Button pushed function: SelectPointsButton
        function SelectPointsButtonPushed(app, event)

            selected_tab = app.ImageTabGroup.SelectedTab.Title;
            labeling = app.LabelingDropDown.Value;
            image_axis_index = str2double(regexp(selected_tab,'\d*','Match'));
            try
                im_axis = app.ChannelAxes{image_axis_index};
            catch
                image_axis_index = numel(app.ChannelAxes);
                im_axis = app.ChannelAxes{image_axis_index};
            end

            XLim = im_axis.XLim;
            YLim = im_axis.YLim;
            tab_number_excluding_merged = (numel(app.ImageTabGroup.Children) - 1);

            tabs_to_copy = 1 : tab_number_excluding_merged+1;

            if  isfield(app.myofibril_data,'profile')
                app.myofibril_data.profile = [];
                for i = 1 : numel(tabs_to_copy)
                    cla(app.ChannelAxes{i})
                    if i ~= tabs_to_copy(end)
                        center_image_with_preserved_aspect_ratio(app.myofibril_data.image{i,1},app.ChannelAxes{i})
                    else
                        center_image_with_preserved_aspect_ratio(app.myofibril_data.fused_image,app.ChannelAxes{i})
                    end
                    app.ChannelAxes{i}.XLim = XLim;
                    app.ChannelAxes{i}.YLim = YLim;
                end

                switch labeling
                    case 'Across'
                        for i = 1 : tab_number_excluding_merged
                            cla(app.BinaryChannelAxes{i})
                            center_image_with_preserved_aspect_ratio(app.myofibril_data.binary_image{i,1},app.BinaryChannelAxes{i})
                            app.BinaryChannelAxes{i}.XLim = XLim;
                            app.BinaryChannelAxes{i}.YLim = YLim;
                        end
                end

                app.RefreshDisplay
                app.Patches = [];
            end


            tabs_to_copy(image_axis_index) = [];
            app.myofibril_data.roi{image_axis_index} = drawpolyline(im_axis,'LineWidth',1E-32,'MarkerSize',6);


            x = app.myofibril_data.roi{image_axis_index}.Position(:,1);
            y = app.myofibril_data.roi{image_axis_index}.Position(:,2);
            cs = spline(x, y);
            app.myofibril_data.profile(image_axis_index).xs = linspace(x(1), x(end), 1000);
            app.myofibril_data.profile(image_axis_index).ys = ppval(cs, app.myofibril_data.profile(image_axis_index).xs);

            hold(im_axis,'on')
            app.SplineLine = cell(1,numel(tabs_to_copy));
            app.SplineLine{image_axis_index} = plot(im_axis,app.myofibril_data.profile(image_axis_index).xs,app.myofibril_data.profile(image_axis_index).ys,"Color",'m','LineWidth',2);

            addlistener(app.myofibril_data.roi{image_axis_index},"ROIMoved",@(src,evt) UpdateROIProfile(app,evt));

            for i = 1 : numel(tabs_to_copy)
                app.myofibril_data.roi{tabs_to_copy(i)} = copyobj(app.myofibril_data.roi{image_axis_index}, app.ChannelAxes{tabs_to_copy(i)});
                addlistener(app.myofibril_data.roi{tabs_to_copy(i)},"ROIMoved",@(src,evt) UpdateROIProfile(app,evt));
                app.SplineLine{tabs_to_copy(i)} = copyobj(app.SplineLine{image_axis_index}, app.ChannelAxes{tabs_to_copy(i)});
                app.ChannelAxes{tabs_to_copy(i)}.XLim = app.ChannelAxes{image_axis_index}.XLim;
                app.ChannelAxes{tabs_to_copy(i)}.YLim = app.ChannelAxes{image_axis_index}.YLim;
            end

            switch labeling
                case 'Across'
                    binary_tabs_to_copy = 1 : tab_number_excluding_merged;
                    for i = 1 : numel(binary_tabs_to_copy)
                        app.myofibril_data.binary_roi{binary_tabs_to_copy(i)} = copyobj(app.myofibril_data.roi{image_axis_index}, app.BinaryChannelAxes{binary_tabs_to_copy(i)});
                        app.BinaryChannelAxes{binary_tabs_to_copy(i)}.XLim = app.ChannelAxes{1}.XLim;
                        app.BinaryChannelAxes{binary_tabs_to_copy(i)}.YLim = app.ChannelAxes{2}.YLim;
                        addlistener(app.myofibril_data.binary_roi{binary_tabs_to_copy(i)},"ROIMoved",@(src,evt) UpdateROIProfile(app,evt));
                        app.BinarySplineLine{binary_tabs_to_copy(i)} = copyobj(app.SplineLine{image_axis_index}, app.BinaryChannelAxes{binary_tabs_to_copy(i)});
                    end
            end

            for channel_no = 1 : tab_number_excluding_merged
                app.myofibril_data.profile(channel_no).xs = app.myofibril_data.profile(image_axis_index).xs;
                app.myofibril_data.profile(channel_no).ys = app.myofibril_data.profile(image_axis_index).ys;
                app.ExtractProfiles(channel_no)
            end

        end

        % Value changed function: PrimaryProminenceEditField
        function PrimaryProminenceEditFieldValueChanged(app, event)
            app.RefreshDisplay;
            if isfield(app.myofibril_data,'profile')
                for channel_no = 1 : size(app.Tabs,2)-1
                    app.ExtractProfiles(channel_no)
                end
            end
        end

        % Value changed function: SecondaryProminenceEditField
        function SecondaryProminenceEditFieldValueChanged(app, event)
            app.RefreshDisplay;
            if isfield(app.myofibril_data,'profile')
                for channel_no = 1 : size(app.Tabs,2)-1
                    app.ExtractProfiles(channel_no)
                end
            end
        end

        % Value changed function: PeakDistancepxEditField
        function PeakDistancepxEditFieldValueChanged(app, event)
            app.RefreshDisplay;
            if isfield(app.myofibril_data,'profile')
                for channel_no = 1 : size(app.Tabs,2)-1
                    app.ExtractProfiles(channel_no)
                end
            end
        end

        % Value changed function: CalibrationumpxEditField
        function CalibrationumpxEditFieldValueChanged(app, event)
            app.RefreshDisplay;
            if isfield(app.myofibril_data,'profile')
                for channel_no = 1 : size(app.Tabs,2)-1
                    app.ExtractProfiles(channel_no)
                end
            end
        end

        % Value changed function: ChannelColorDropDown
        function ChannelColorDropDownValueChanged(app, event)
            app.ColorScheme;
            app.PseudoColoring;
            app.RefreshDisplay;
            if isfield(app.myofibril_data,'roi')
                app.myofibril_data.roi{size(app.Tabs,2)} = copyobj(app.myofibril_data.roi{1}, app.ChannelAxes{size(app.Tabs,2)});
                addlistener(app.myofibril_data.roi{size(app.Tabs,2)},"ROIMoved",@(src,evt) UpdateROIProfile(app,evt));
                app.SplineLine{size(app.Tabs,2)} = copyobj(app.SplineLine{1}, app.ChannelAxes{size(app.Tabs,2)});
                if isfield(app.myofibril_data,'profile')
                    for channel_no = 1 : size(app.Tabs,2)-1
                        app.ExtractProfiles(channel_no)
                    end
                end
            end
        end

        % Menu selected function: ExportAnalysisMenu
        function ExportAnalysisMenuSelected(app, event)
            [file_string,path_string] = uiputfile2( ...
                {'*.xlsx','Excel file'},'Enter Excel File Name For Analysis Results');
            labeling = app.LabelingDropDown.Value;

            if (path_string~=0)
                output_file_string = fullfile(path_string,file_string);

                try
                    delete(output_file_string);
                end

                no_of_channels = size(app.myofibril_data.profile,2);

                summary_fields = {'image_file','px_to_um_calibration',...
                    'channel_no',...
                    'mean_sarcomere_length_um','std_sarcomere_length_um',...
                    'sem_sarcomere_length_um'};

                sarcomere_summary_fields = {'channel_no','sarcomere_index',...
                    'sarcomere_length_um'};

                for i = 1 : no_of_channels
                    figure_name = erase(output_file_string,'.xlsx');
                    figure_name = sprintf('%s_analyzed_image_channel_%i.png',figure_name,i);
                    exportgraphics(app.ChannelAxes{i},figure_name, ...
                        Resolution = 700, ...
                        ContentType = "vector")
                end

                 figure_name = sprintf('%s_analyzed_image_merged.png',figure_name);
                 exportgraphics(app.ChannelAxes{end},figure_name, ...
                     Resolution = 700, ...
                     ContentType = "vector")

                switch labeling
                    case 'Along'
                        summary_fields = [summary_fields {'mean_fwhm_um','std_fwhm_um','sem_fwhm_um'}];
                        sarcomere_summary_fields = [sarcomere_summary_fields {'fwhm_um'}];
                    case 'Across'
                        summary_fields = [summary_fields {'mean_tortuosity','std_tortuosity','sem_tortuosity','mean_fwhm_um','std_fwhm_um','sem_fwhm_um'}];
                        metrics_summary_fields = {'channel_no','line_index','tortuosity','fwhm_um'};
                        for i = 1 : numel(metrics_summary_fields)
                            metrics_out.(metrics_summary_fields{i}) = [];
                        end

                        for i = 1 : no_of_channels
                            figure_name = erase(output_file_string,'.xlsx');
                            figure_name = sprintf('%s_analyzed_binary_image_channel_%i.png',figure_name,i);
                            exportgraphics(app.BinaryChannelAxes{i},figure_name, ...
                                Resolution = 700, ...
                                ContentType = "vector")
                        end
                end

                for i = 1 : numel(summary_fields)
                    sum_out.(summary_fields{i}) = [];
                end

                for i = 1 : numel(sarcomere_summary_fields)
                    sarcomere_out.(sarcomere_summary_fields{i}) = [];
                end


                dat_type = app.myofibril_data.image_file_string;

                if ischar(dat_type)
                    sum_out.image_file = app.myofibril_data.image_file_string;
                else
                    sum_out.image_file{1} = app.myofibril_data.image_file_string{1};
                end
                sum_out.px_to_um_calibration = num2str(app.myofibril_data.calibration);

                for i = 1 : no_of_channels

                    sum_out.channel_no(i,1) = i;
                    sum_out.mean_sarcomere_length_um(i,1) = mean(app.myofibril_data.profile(i).sarcomere_lengths);
                    sum_out.std_sarcomere_length_um(i,1) = std(app.myofibril_data.profile(i).sarcomere_lengths);
                    sum_out.sem_sarcomere_length_um(i,1) = std(app.myofibril_data.profile(i).sarcomere_lengths)/sqrt(numel(app.myofibril_data.profile(i).sarcomere_lengths));

                    switch labeling
                        case 'Along'
                            sum_out.mean_fwhm_um(i,1) = mean(app.myofibril_data.profile(i).fwhm);
                            sum_out.std_fwhm_um(i,1) = std(app.myofibril_data.profile(i).fwhm);
                            sum_out.sem_fwhm_um(i,1) = std(app.myofibril_data.profile(i).fwhm)/sqrt(numel(app.myofibril_data.profile(i).fwhm));
                        case 'Across'
                            sum_out.mean_tortuosity(i,1) = mean(app.myofibril_data.profile(i).tortuosity);
                            sum_out.std_tortuosity(i,1) = std(app.myofibril_data.profile(i).tortuosity);
                            sum_out.sem_tortuosity(i,1) = std(app.myofibril_data.profile(i).tortuosity)/sqrt(numel(app.myofibril_data.profile(i).tortuosity));
                            sum_out.mean_fwhm_um(i,1) = mean(app.myofibril_data.profile(i).fwhm);
                            sum_out.std_fwhm_um(i,1) = std(app.myofibril_data.profile(i).fwhm);
                            sum_out.sem_fwhm_um(i,1) = std(app.myofibril_data.profile(i).fwhm)/sqrt(numel(app.myofibril_data.profile(i).fwhm));
                    end
                end

                switch labeling
                    case 'Along'
                        sarcomere_out = app.SummaryTableABand.Data;
                    case 'Across'
                        sarcomere_out = app.SummaryTableZLineSL.Data;
                        metrics_out = app.SummaryTableZLineMetrics.Data;
                end


                if numel(app.myofibril_data.image_file_string) > 1 && ~ischar(dat_type)
                    for i = 2 : no_of_channels
                        sum_out.image_file{i,1} = app.myofibril_data.image_file_string{i};
                    end
                else
                    for i = 2 : no_of_channels
                        sum_out.image_file(i,:) = app.myofibril_data.image_file_string;
                    end
                end
                sum_out.px_to_um_calibration(2:no_of_channels,1) = sum_out.px_to_um_calibration(1);
                writetable(struct2table(sum_out),output_file_string,'Sheet','Analysis Summary')
                writetable(sarcomere_out,output_file_string,'Sheet','Sarcomere Summary')
                if strcmp(labeling,'Across')
                    writetable(metrics_out,output_file_string,'Sheet','Metrics Summary')
                end


                for i = 1 : no_of_channels
                    channel_name = sprintf('channel_%i',i);
                    sum_sheet_name = sprintf('Channel %i Summary Profiles',i);
                    sheet_name = sprintf('Channel %i Sarcomere Profiles',i);

                    sarcomere.sum_profiles.(channel_name).location_um = app.myofibril_data.profile(i).mean_sarcomere_location';
                    sarcomere.sum_profiles.(channel_name).mean_sarcomere_profile = app.myofibril_data.profile(i).mean_sarcomere_profile';
                    sarcomere.sum_profiles.(channel_name).std_sarcomere_profile = app.myofibril_data.profile(i).std_sarcomere_profile';
                    sarcomere.sum_profiles.(channel_name).sem_sarcomere_profile = app.myofibril_data.profile(i).sem_sarcomere_profile';

                    writetable(struct2table(sarcomere.sum_profiles.(channel_name)),output_file_string,'Sheet',sum_sheet_name)


                    if ~isempty(app.myofibril_data.profile(i).sarcomere_lengths)
                        for j = 1 : numel(app.myofibril_data.profile(i).sarcomere_lengths)
                            var_name = sprintf('sarcomere_intensity_%i',j);
                            location_name = sprintf('location_um_%i',j);
                            sarcomere.(channel_name).(location_name) = app.myofibril_data.profile(i).sarcomere_location(j,:)';
                            sarcomere.(channel_name).(var_name) = app.myofibril_data.profile(i).sarcomere_intensities(j,:)';
                        end

                        writetable(struct2table(sarcomere.(channel_name)),output_file_string,'Sheet',sheet_name)
                    end

                end

                output_file_string = replace(output_file_string,'.xlsx','.myoprof');
                analysis_session = app.myofibril_data;
                analysis_session.roi_width = app.WidthpxEditField.Value;
                analysis_session.z_prominence = app.PrimaryProminenceEditField.Value;
                analysis_session.a_prominence = app.SecondaryProminenceEditField.Value;
                analysis_session.peak_distance = app.PeakDistancepxEditField.Value;

                save(output_file_string,'analysis_session')

            end
        end

        % Value changed function: WidthpxEditField
        function WidthpxEditFieldValueChanged(app, event)
            roi_width = app.WidthpxEditField.Value;
            if  isfield(app.myofibril_data,'profile')
                app.RefreshDisplay;
                if ~isempty(app.Patches)
                    for i = 1 : numel(app.Patches)
                        app.Patches{i}.FaceAlpha = 0;
                    end
                end
                for channel_no = 1 : size(app.Tabs,2)-1
                    app.ExtractProfiles(channel_no)
                end
                if roi_width > 1
                    app.Patches{numel(app.Tabs)} = copyobj(app.Patches{1}, app.ChannelAxes{numel(app.Tabs)});
                end
            end
        end

        % Menu selected function: LoadAnalysisMenu
        function LoadAnalysisMenuSelected(app, event)
            f = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file_string,path_string] = uigetfile2( ...
                {'*.myoprof','MyofibrilProfiler file'},'Select MyoProf File To Load Analysis');
            delete(f);

            if (path_string~=0)
                app.SplineLine = [];
                app.Patches = [];

                temp = load(fullfile(path_string,file_string),'-mat','analysis_session');
                analysis_session = temp.analysis_session;
                app.myofibril_data = [];
                app.myofibril_data.image_file_string = analysis_session.image_file_string;
                im_ax = app.ImageAxes;
                app.Tabs = [];
                app.ChannelAxes = [];
                app.RefreshDisplay;
                app.WidthpxEditField.Value = analysis_session.roi_width;
                app.PrimaryProminenceEditField.Value = analysis_session.z_prominence;
                app.SecondaryProminenceEditField.Value = analysis_session.a_prominence ;
                app.PeakDistancepxEditField.Value = analysis_session.peak_distance;
                app.CalibrationumpxEditField.Value = analysis_session.calibration;
                if contains(analysis_session.image_file_string,'.nd2')
                    app.myofibril_data.image_file = analysis_session.image_file;
                    app.myofibril_data.meta_file = app.myofibril_data.image_file{1,2};
                    app.myofibril_data.em_wavelengths = analysis_session.em_wavelengths;
                    h = app.myofibril_data.meta_file;
                    im = analysis_session.image;
                    app.myofibril_data.image = im;
                else
                    app.myofibril_data = deal(analysis_session);
                end

                sz = numel(app.myofibril_data.image);
                delete(app.ImageTabGroup.Children)
                for i = 1:sz
                    app.Tabs{i} = uitab(app.ImageTabGroup,'Title',['Channel ' num2str(i)]);
                    app.ChannelAxes{i} = copyobj(im_ax,app.Tabs{i});
                    app.ChannelAxes{i}.Visible = 'on';
                    center_image_with_preserved_aspect_ratio(app.myofibril_data.image{i,1},app.ChannelAxes{i})
                    % app.myofibril_data.pseudo_color_images{i,1} = app.myofibril_data.image{i,1};
                end
                app.Tabs{end+1} = uitab(app.ImageTabGroup,'Title','Merged ');
                app.ChannelAxes{end+1} = copyobj(im_ax,app.Tabs{end});
                app.ChannelAxes{end}.Visible = 'on';
                app.ColorScheme;
                app.PseudoColoring;


                number_of_rois = numel(analysis_session.roi);

                pos = analysis_session.roi{1}.Position;
                app.myofibril_data.roi{1} = drawpolyline(app.ChannelAxes{1},'Position',pos,'LineWidth',1E-32,'MarkerSize',6);

                x = app.myofibril_data.roi{1}.Position(:,1);
                y = app.myofibril_data.roi{1}.Position(:,2);
                cs = spline(x, y);
                app.myofibril_data.profile(1).xs = linspace(x(1), x(end), 1000);
                app.myofibril_data.profile(1).ys = ppval(cs, app.myofibril_data.profile(1).xs);

                hold(app.ChannelAxes{1},'on')
                app.SplineLine = cell(1,numel(app.ChannelAxes));
                app.SplineLine{1} = plot(app.ChannelAxes{1},app.myofibril_data.profile(1).xs,app.myofibril_data.profile(1).ys,"Color",'m','LineWidth',2);

                addlistener(app.myofibril_data.roi{1},"ROIMoved",@(src,evt) UpdateROIProfile(app,evt));

                for i = 2 : numel(app.ChannelAxes)
                    app.myofibril_data.roi{i} = copyobj(app.myofibril_data.roi{1}, app.ChannelAxes{i});
                    addlistener(app.myofibril_data.roi{i},"ROIMoved",@(src,evt) UpdateROIProfile(app,evt));
                    app.SplineLine{i} = copyobj(app.SplineLine{1}, app.ChannelAxes{i});
                end
                tab_number_excluding_merged = numel(app.ChannelAxes)-1;

                if isfield(analysis_session,'binary_image')
                    app.LoadedAnalysis = 1;
                    app.LabelingDropDown.Value = 'Across';
                    app.LabelingDropDownValueChanged;
                    app.BinarizeImages;
                    binary_tabs_to_copy = 1 : tab_number_excluding_merged;
                    for i = 1 : numel(binary_tabs_to_copy)
                        app.myofibril_data.binary_roi{i} = copyobj(app.myofibril_data.roi{1}, app.BinaryChannelAxes{i});
                        addlistener(app.myofibril_data.binary_roi{i},"ROIMoved",@(src,evt) UpdateROIProfile(app,evt));
                        app.BinarySplineLine{i} = copyobj(app.SplineLine{1}, app.BinaryChannelAxes{i});
                    end
                    app.LoadedAnalysis = 0;
                end

                
                for channel_no = 1 : tab_number_excluding_merged
                    app.myofibril_data.profile(channel_no).xs = app.myofibril_data.profile(1).xs;
                    app.myofibril_data.profile(channel_no).ys = app.myofibril_data.profile(1).ys;
                    app.ExtractProfiles(channel_no)
                end
            end
        end

        % Value changed function: LabelingDropDown
        function LabelingDropDownValueChanged(app, event)
            labeling = app.LabelingDropDown.Value;
            app.RefreshDisplay;

            switch labeling
                case 'Across'
                    app.SecondaryProminenceEditField.Enable = 'off';
                    app.ABandProminenceEditFieldLabel.Enable = 'off';
                    app.AnalysisPanelABand.Enable = 'off';
                    app.AnalysisPanelABand.Visible = 'off';
                    app.ZLineAnalysisTabGroup.Visible = 'on';

                    app.AnalysisPanelZLine.Enable = 'on';
                    app.AnalysisPanelZLine.Visible = 'on';
                    if isfield(app.myofibril_data,'image') && ~app.LoadedAnalysis
                        app.BinarizeImages
                    end

                case 'Along'
                    app.SecondaryProminenceEditField.Enable = 'on';
                    app.ABandProminenceEditFieldLabel.Enable = 'on';
                    app.AnalysisPanelABand.Enable = 'on';
                    app.AnalysisPanelABand.Visible = 'on';

                    app.AnalysisPanelZLine.Enable = 'off';
                    app.AnalysisPanelZLine.Visible = 'off';
            end
            if isfield(app.myofibril_data,'profile') && ~app.LoadedAnalysis
                for channel_no = 1 : size(app.Tabs,2)-1
                    app.ExtractProfiles(channel_no)
                end
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MyoProfilerUIFigure and hide until all components are created
            app.MyoProfilerUIFigure = uifigure('Visible', 'off');
            app.MyoProfilerUIFigure.Position = [92 92 1349 601];
            app.MyoProfilerUIFigure.Name = 'MyoProfiler';

            % Create Menu
            app.Menu = uimenu(app.MyoProfilerUIFigure);
            app.Menu.Text = 'Menu';

            % Create LoadImageMenu
            app.LoadImageMenu = uimenu(app.Menu);
            app.LoadImageMenu.Text = 'Load Image';

            % Create NikonMenu
            app.NikonMenu = uimenu(app.LoadImageMenu);
            app.NikonMenu.MenuSelectedFcn = createCallbackFcn(app, @NikonImageSelected, true);
            app.NikonMenu.Text = 'Nikon';

            % Create ZeissMenu
            app.ZeissMenu = uimenu(app.LoadImageMenu);
            app.ZeissMenu.MenuSelectedFcn = createCallbackFcn(app, @ZeissMenuSelected, true);
            app.ZeissMenu.Text = 'Zeiss';

            % Create StandardFormatsMenu
            app.StandardFormatsMenu = uimenu(app.LoadImageMenu);
            app.StandardFormatsMenu.MenuSelectedFcn = createCallbackFcn(app, @StandardFormatsImageSelected, true);
            app.StandardFormatsMenu.Text = 'Standard Formats';

            % Create LoadAnalysisMenu
            app.LoadAnalysisMenu = uimenu(app.Menu);
            app.LoadAnalysisMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadAnalysisMenuSelected, true);
            app.LoadAnalysisMenu.Text = 'Load Analysis';

            % Create ExportAnalysisMenu
            app.ExportAnalysisMenu = uimenu(app.Menu);
            app.ExportAnalysisMenu.MenuSelectedFcn = createCallbackFcn(app, @ExportAnalysisMenuSelected, true);
            app.ExportAnalysisMenu.Text = 'Export Analysis';

            % Create ImageDisplayPanel
            app.ImageDisplayPanel = uipanel(app.MyoProfilerUIFigure);
            app.ImageDisplayPanel.Title = 'Image Display';
            app.ImageDisplayPanel.Position = [6 10 454 392];

            % Create ImageAxes
            app.ImageAxes = uiaxes(app.ImageDisplayPanel);
            app.ImageAxes.XTick = [];
            app.ImageAxes.YTick = [];
            app.ImageAxes.Box = 'on';
            app.ImageAxes.Visible = 'off';
            app.ImageAxes.Position = [17 14 399 298];

            % Create ImageTabGroup
            app.ImageTabGroup = uitabgroup(app.ImageDisplayPanel);
            app.ImageTabGroup.Position = [5 7 445 358];

            % Create ImageTab
            app.ImageTab = uitab(app.ImageTabGroup);
            app.ImageTab.Title = 'Image';

            % Create ProfilerPanel
            app.ProfilerPanel = uipanel(app.MyoProfilerUIFigure);
            app.ProfilerPanel.Title = 'Profiler Panel';
            app.ProfilerPanel.Position = [468 10 432 586];

            % Create ProfileIntensity
            app.ProfileIntensity = uiaxes(app.ProfilerPanel);
            title(app.ProfileIntensity, 'Extracted Profile')
            xlabel(app.ProfileIntensity, 'Horizontal Location (px)')
            ylabel(app.ProfileIntensity, 'Vertical Location (px)')
            zlabel(app.ProfileIntensity, {'Normalized Intensity'; 'Over Full Range'})
            app.ProfileIntensity.Box = 'on';
            app.ProfileIntensity.Position = [8 373 415 182];

            % Create ProfileIntensityXCoord
            app.ProfileIntensityXCoord = uiaxes(app.ProfilerPanel);
            title(app.ProfileIntensityXCoord, 'Profile Intensity')
            xlabel(app.ProfileIntensityXCoord, 'Horizontal Location (px)')
            ylabel(app.ProfileIntensityXCoord, {'Normalized Intensity'; 'Over Full Range'})
            zlabel(app.ProfileIntensityXCoord, 'Z')
            app.ProfileIntensityXCoord.Box = 'on';
            app.ProfileIntensityXCoord.Position = [10 197 415 160];

            % Create ProfileIntensityYCoord
            app.ProfileIntensityYCoord = uiaxes(app.ProfilerPanel);
            title(app.ProfileIntensityYCoord, 'Profile Intensity')
            xlabel(app.ProfileIntensityYCoord, 'Vertical Location (px)')
            ylabel(app.ProfileIntensityYCoord, {'Normalized Intensity'; 'Over Full Range'})
            zlabel(app.ProfileIntensityYCoord, 'Z')
            app.ProfileIntensityYCoord.Box = 'on';
            app.ProfileIntensityYCoord.Position = [10 20 415 160];

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.MyoProfilerUIFigure);
            app.ControlsPanel.Title = 'Controls';
            app.ControlsPanel.Position = [6 406 454 190];

            % Create LabelingPanel
            app.LabelingPanel = uipanel(app.ControlsPanel);
            app.LabelingPanel.Title = 'Labeling';
            app.LabelingPanel.Position = [5 111 100 53];

            % Create LabelingDropDown
            app.LabelingDropDown = uidropdown(app.LabelingPanel);
            app.LabelingDropDown.Items = {'Along', 'Across'};
            app.LabelingDropDown.ValueChangedFcn = createCallbackFcn(app, @LabelingDropDownValueChanged, true);
            app.LabelingDropDown.Position = [6 5 74 22];
            app.LabelingDropDown.Value = 'Along';

            % Create ChannelColormapPanel
            app.ChannelColormapPanel = uipanel(app.ControlsPanel);
            app.ChannelColormapPanel.Title = 'Channel Colormap';
            app.ChannelColormapPanel.Position = [108 111 135 53];

            % Create ChannelColorDropDown
            app.ChannelColorDropDown = uidropdown(app.ChannelColormapPanel);
            app.ChannelColorDropDown.Items = {'Em. Wavelength', 'Parula'};
            app.ChannelColorDropDown.ValueChangedFcn = createCallbackFcn(app, @ChannelColorDropDownValueChanged, true);
            app.ChannelColorDropDown.Position = [6 5 121 22];
            app.ChannelColorDropDown.Value = 'Em. Wavelength';

            % Create ROIPanel
            app.ROIPanel = uipanel(app.ControlsPanel);
            app.ROIPanel.Title = 'ROI';
            app.ROIPanel.Position = [247 111 202 53];

            % Create SelectPointsButton
            app.SelectPointsButton = uibutton(app.ROIPanel, 'push');
            app.SelectPointsButton.ButtonPushedFcn = createCallbackFcn(app, @SelectPointsButtonPushed, true);
            app.SelectPointsButton.Position = [8 5 85 23];
            app.SelectPointsButton.Text = 'Select Points';

            % Create WidthpxEditFieldLabel
            app.WidthpxEditFieldLabel = uilabel(app.ROIPanel);
            app.WidthpxEditFieldLabel.HorizontalAlignment = 'center';
            app.WidthpxEditFieldLabel.Position = [93 5 78 22];
            app.WidthpxEditFieldLabel.Text = 'Width (px)';

            % Create WidthpxEditField
            app.WidthpxEditField = uieditfield(app.ROIPanel, 'numeric');
            app.WidthpxEditField.ValueChangedFcn = createCallbackFcn(app, @WidthpxEditFieldValueChanged, true);
            app.WidthpxEditField.Position = [162 5 32 22];
            app.WidthpxEditField.Value = 1;

            % Create ProfilePanel
            app.ProfilePanel = uipanel(app.ControlsPanel);
            app.ProfilePanel.Title = 'Profile';
            app.ProfilePanel.Position = [5 8 444 96];

            % Create CalibrationumpxEditFieldLabel
            app.CalibrationumpxEditFieldLabel = uilabel(app.ProfilePanel);
            app.CalibrationumpxEditFieldLabel.HorizontalAlignment = 'right';
            app.CalibrationumpxEditFieldLabel.Position = [225 9 106 22];
            app.CalibrationumpxEditFieldLabel.Text = 'Calibration (um/px)';

            % Create CalibrationumpxEditField
            app.CalibrationumpxEditField = uieditfield(app.ProfilePanel, 'numeric');
            app.CalibrationumpxEditField.Limits = [0 Inf];
            app.CalibrationumpxEditField.ValueChangedFcn = createCallbackFcn(app, @CalibrationumpxEditFieldValueChanged, true);
            app.CalibrationumpxEditField.Position = [360 9 70 22];
            app.CalibrationumpxEditField.Value = 1;

            % Create PeakDistancepxEditFieldLabel
            app.PeakDistancepxEditFieldLabel = uilabel(app.ProfilePanel);
            app.PeakDistancepxEditFieldLabel.HorizontalAlignment = 'center';
            app.PeakDistancepxEditFieldLabel.WordWrap = 'on';
            app.PeakDistancepxEditFieldLabel.Position = [228 35 104 32];
            app.PeakDistancepxEditFieldLabel.Text = 'Peak Distance (px)';

            % Create PeakDistancepxEditField
            app.PeakDistancepxEditField = uieditfield(app.ProfilePanel, 'numeric');
            app.PeakDistancepxEditField.Limits = [0 Inf];
            app.PeakDistancepxEditField.ValueChangedFcn = createCallbackFcn(app, @PeakDistancepxEditFieldValueChanged, true);
            app.PeakDistancepxEditField.Position = [391 40 39 22];
            app.PeakDistancepxEditField.Value = 50;

            % Create ZLineProminenceEditFieldLabel
            app.ZLineProminenceEditFieldLabel = uilabel(app.ProfilePanel);
            app.ZLineProminenceEditFieldLabel.HorizontalAlignment = 'right';
            app.ZLineProminenceEditFieldLabel.Position = [8 40 114 22];
            app.ZLineProminenceEditFieldLabel.Text = 'Primary Prominence';

            % Create PrimaryProminenceEditField
            app.PrimaryProminenceEditField = uieditfield(app.ProfilePanel, 'numeric');
            app.PrimaryProminenceEditField.Limits = [0 1];
            app.PrimaryProminenceEditField.ValueChangedFcn = createCallbackFcn(app, @PrimaryProminenceEditFieldValueChanged, true);
            app.PrimaryProminenceEditField.Position = [149 42 39 22];
            app.PrimaryProminenceEditField.Value = 0.05;

            % Create ABandProminenceEditFieldLabel
            app.ABandProminenceEditFieldLabel = uilabel(app.ProfilePanel);
            app.ABandProminenceEditFieldLabel.HorizontalAlignment = 'right';
            app.ABandProminenceEditFieldLabel.Position = [7 9 130 22];
            app.ABandProminenceEditFieldLabel.Text = 'Secondary Prominence';

            % Create SecondaryProminenceEditField
            app.SecondaryProminenceEditField = uieditfield(app.ProfilePanel, 'numeric');
            app.SecondaryProminenceEditField.Limits = [0 1];
            app.SecondaryProminenceEditField.ValueChangedFcn = createCallbackFcn(app, @SecondaryProminenceEditFieldValueChanged, true);
            app.SecondaryProminenceEditField.Position = [149 9 39 22];
            app.SecondaryProminenceEditField.Value = 0.05;

            % Create AnalysisPanelABand
            app.AnalysisPanelABand = uipanel(app.MyoProfilerUIFigure);
            app.AnalysisPanelABand.Title = 'Analysis Panel';
            app.AnalysisPanelABand.Position = [908 10 432 586];

            % Create SarcomereMean
            app.SarcomereMean = uiaxes(app.AnalysisPanelABand);
            title(app.SarcomereMean, 'Average Sarcomere Intensity')
            xlabel(app.SarcomereMean, 'Location (um)')
            ylabel(app.SarcomereMean, {'Normalized Intensity'; 'Over Sarcomere'})
            app.SarcomereMean.Box = 'on';
            app.SarcomereMean.Position = [9 396 415 160];

            % Create Sarcomeres
            app.Sarcomeres = uiaxes(app.AnalysisPanelABand);
            title(app.Sarcomeres, 'Sarcomere Intensities')
            xlabel(app.Sarcomeres, 'Location (um)')
            ylabel(app.Sarcomeres, {'Normalized Intensity'; 'Over Sarcomere'})
            app.Sarcomeres.Box = 'on';
            app.Sarcomeres.Position = [8 215 415 160];

            % Create SummaryTableABand
            app.SummaryTableABand = uitable(app.AnalysisPanelABand);
            app.SummaryTableABand.ColumnName = {'Channel'; 'Profile Number'; 'Color'; 'SL (um)'; 'FWHM (um)'};
            app.SummaryTableABand.RowName = {};
            app.SummaryTableABand.Position = [8 18 417 179];

            % Create AnalysisPanelZLine
            app.AnalysisPanelZLine = uipanel(app.MyoProfilerUIFigure);
            app.AnalysisPanelZLine.Enable = 'off';
            app.AnalysisPanelZLine.Title = 'Analysis Panel';
            app.AnalysisPanelZLine.Visible = 'off';
            app.AnalysisPanelZLine.Position = [908 10 432 586];

            % Create BinaryTabGroup
            app.BinaryTabGroup = uitabgroup(app.AnalysisPanelZLine);
            app.BinaryTabGroup.Position = [7 216 417 345];

            % Create BinaryTab
            app.BinaryTab = uitab(app.BinaryTabGroup);
            app.BinaryTab.Title = 'Binary';

            % Create ZLineAnalysisTabGroup
            app.ZLineAnalysisTabGroup = uitabgroup(app.AnalysisPanelZLine);
            app.ZLineAnalysisTabGroup.Position = [8 18 417 179];

            % Create SarcomereLengthTab
            app.SarcomereLengthTab = uitab(app.ZLineAnalysisTabGroup);
            app.SarcomereLengthTab.Title = 'Sarcomere Length';

            % Create SummaryTableZLineSL
            app.SummaryTableZLineSL = uitable(app.SarcomereLengthTab);
            app.SummaryTableZLineSL.ColumnName = {'Channel'; 'Profile Number'; 'SL (um)'};
            app.SummaryTableZLineSL.RowName = {};
            app.SummaryTableZLineSL.Position = [10 9 399 138];

            % Create MetricsTab
            app.MetricsTab = uitab(app.ZLineAnalysisTabGroup);
            app.MetricsTab.Title = 'Metrics';

            % Create SummaryTableZLineMetrics
            app.SummaryTableZLineMetrics = uitable(app.MetricsTab);
            app.SummaryTableZLineMetrics.ColumnName = {'Channel'; 'Line Number'; 'Tortuosity'; 'FWHM (um)'};
            app.SummaryTableZLineMetrics.RowName = {};
            app.SummaryTableZLineMetrics.Position = [10 9 399 138];

            % Show the figure after all components are created
            app.MyoProfilerUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MyoProfiler_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.MyoProfilerUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.MyoProfilerUIFigure)
        end
    end
end