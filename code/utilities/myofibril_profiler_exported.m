classdef myofibril_profiler_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MyofibrilProfilerUIFigure       matlab.ui.Figure
        Menu                            matlab.ui.container.Menu
        LoadImageMenu                   matlab.ui.container.Menu
        ExportResultsMenu               matlab.ui.container.Menu
        LoadMeasurementMenu             matlab.ui.container.Menu
        ROIControlsPanel                matlab.ui.container.Panel
        NoofLinesEditField              matlab.ui.control.NumericEditField
        ofLinesLabel                    matlab.ui.control.Label
        LineSeperationpxEditField       matlab.ui.control.NumericEditField
        LineSeperationpxEditFieldLabel  matlab.ui.control.Label
        ScanLinesButton                 matlab.ui.control.Button
        ScanPointsButton                matlab.ui.control.Button
        ProfilerPanel                   matlab.ui.container.Panel
        SarcomereMean                   matlab.ui.control.UIAxes
        Sarcomeres                      matlab.ui.control.UIAxes
        ProfileIntensity                matlab.ui.control.UIAxes
        ProfilerControlsPanel           matlab.ui.container.Panel
        ProminenceEditField             matlab.ui.control.NumericEditField
        ProminenceEditFieldLabel        matlab.ui.control.Label
        CalibrationumpxEditField        matlab.ui.control.NumericEditField
        CalibrationumpxEditFieldLabel   matlab.ui.control.Label
        ImageSpinner                    matlab.ui.control.Spinner
        ImageSpinnerLabel               matlab.ui.control.Label
        ImageDisplayPanel               matlab.ui.container.Panel
        ImageAxes                       matlab.ui.control.UIAxes
        DataHandlerPanel                matlab.ui.container.Panel
        ImageFileEditField              matlab.ui.control.EditField
        ImageFileEditFieldLabel         matlab.ui.control.Label
    end

    
    properties (Access = public)
        myofibril_data = []
        spline_line
        shaded_stats
    end
    
    methods (Access = public)
        
        function ExtractProfiles(app)
            
            im_file = app.myofibril_data.image_file;
            selected_im = app.ImageSpinner.Value;
            xs = app.myofibril_data.profile.xs;
            ys = app.myofibril_data.profile.ys;
            prominence = app.ProminenceEditField.Value;
            calibration = app.CalibrationumpxEditField.Value;

            im = im_file{1,1}{selected_im,1};

            im_profile = improfile(im, xs, ys);
            x_profile = 1:numel(im_profile);

            [pks, locs] = findpeaks(-im_profile, ...
            'MinPeakProminence', prominence * range(im_profile));
            

            no_of_sarcomeres = numel(locs) - 1;

            for i = 1 : no_of_sarcomeres
                sarc_len(i) = calibration*(locs(i+1) - locs(i))
            end

            mean_sarc_len = mean(sarc_len)

            x_sarc_profile = linspace(0, mean_sarc_len, 1000);
            for i = 1 : no_of_sarcomeres
                profile_indices = locs(i) : locs(i+1);
                x_temp = mean_sarc_len*normalize(profile_indices, 'range')
                y_sarc_profile(i, :) = interp1(x_temp, im_profile(profile_indices), ...
                    x_sarc_profile);
                y_sarc_profile(i,:) = normalize(y_sarc_profile(i,:),'range');
            end

            mean_sarc_profile = mean(y_sarc_profile);

            fwhm_ix(1) = find(mean_sarc_profile >= 0.5,1,'first')
            fwhm_ix(2) = find(mean_sarc_profile >= 0.5,1,'last')
            fwhm = x_sarc_profile(fwhm_ix(2)) - x_sarc_profile(fwhm_ix(1))

            hold(app.ProfileIntensity,'on')
            plot(app.ProfileIntensity,x_profile,im_profile,'b-');
            scatter(app.ProfileIntensity,locs,-pks,80,'MarkerEdgeColor',[0 0 0],...
                                                      'MarkerFaceColor',[0 1 0],...
                                                      'MarkerFaceAlpha',0.5)
            
            
            plot(app.Sarcomeres,x_sarc_profile,y_sarc_profile)
            colororder(app.Sarcomeres,parula(size(y_sarc_profile,1)))
            shadedErrorBar2(x_sarc_profile, y_sarc_profile, {@mean, @std},'-k',0,app.SarcomereMean);
            hold(app.SarcomereMean,'on')
            plot(app.SarcomereMean,x_sarc_profile(fwhm_ix(1):fwhm_ix(2)),linspace(mean_sarc_profile(fwhm_ix(1)),...
                mean_sarc_profile(fwhm_ix(2)),numel(fwhm_ix(1):fwhm_ix(2))),':m')
            xlim(app.Sarcomeres,[0 mean_sarc_len])
            xlim(app.SarcomereMean,[0 mean_sarc_len])
            
            mean_sarc_len_leg = sprintf("Mean sarcomere length = %.2f um", mean_sarc_len)
            fwhm_leg = sprintf('FWHM = %.2f um',fwhm);
            legend(app.SarcomereMean,'','','',mean_sarc_len_leg,fwhm_leg)

            app.myofibril_data.profile.intensity = im_profile;
            app.myofibril_data.profile.sarcomere_intensities = y_sarc_profile;
            app.myofibril_data.profile.sarcomere_location = x_sarc_profile;
            app.myofibril_data.profile.mean_sarcomere_profile = mean_sarc_profile;
            app.myofibril_data.profile.std_sarcomere_profile = std(y_sarc_profile);
            app.myofibril_data.profile.sem_sarcomere_profile = std(y_sarc_profile)/sqrt(length(y_sarc_profile));
            app.myofibril_data.profile.sarcomere_lengths = sarc_len;
            app.myofibril_data.profile.fwhm = fwhm;
            app.myofibril_data.calibration = calibration;
            

            
            
        end
        
        function RefreshDisplay(app)

            ax = {'ProfileIntensity','Sarcomeres','SarcomereMean'};
            
            for i = 1:numel(ax)
                cla(app.(ax{i}))
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            addpath(genpath('utilities'))
            movegui(app.MyofibrilProfilerUIFigure,'center')
            colormap(app.ImageAxes, 'gray');
        end

        % Menu selected function: LoadImageMenu
        function LoadImageMenuSelected(app, event)
            f = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);
            [file_string,path_string]=uigetfile2( ...
                {'*.nd2'}, ...
                'Select Image File');
            if (path_string~=0)
                delete(f)
                app.myofibril_data = [];
                app.myofibril_data.image_file_string = fullfile(path_string,file_string);
                app.ImageFileEditField.Value = app.myofibril_data.image_file_string;
                app.myofibril_data.image_file = bfopen(app.myofibril_data.image_file_string);
                im = app.myofibril_data.image_file;
                sz = size(im{1,1});

                app.ImageSpinner.Value = 1;
                app.ImageSpinner.Limits = [1 sz(1)];
                app.RefreshDisplay

                center_image_with_preserved_aspect_ratio(im{1,1}{1,1},app.ImageAxes)
                
            end
        end

        % Value changed function: ImageSpinner
        function ImageSpinnerValueChanged(app, event)
            value = app.ImageSpinner.Value;
            im = app.myofibril_data.image_file;
            center_image_with_preserved_aspect_ratio(im{1,1}{value,1},app.ImageAxes)
        end

        % Button pushed function: ScanPointsButton
        function ScanPointsButtonPushed(app, event)
            
            if  isfield(app.myofibril_data,'profile')
                app.myofibril_data.profile = [];
                cla(app.ImageAxes)
                center_image_with_preserved_aspect_ratio(app.myofibril_data.image_file{1,1}{app.ImageSpinner.Value,1},app.ImageAxes)
                app.RefreshDisplay
            end

            app.myofibril_data.profile.roi = drawpolyline(app.ImageAxes,'LineWidth',1E-32,'MarkerSize',10);

            
            x = app.myofibril_data.profile.roi.Position(:,1);
            y = app.myofibril_data.profile.roi.Position(:,2);
            cs = spline(x, y);
            app.myofibril_data.profile.xs = linspace(x(1), x(end), 1000);
            app.myofibril_data.profile.ys = ppval(cs, app.myofibril_data.profile.xs);

            hold(app.ImageAxes,'on')
            app.spline_line = plot(app.ImageAxes,app.myofibril_data.profile.xs,app.myofibril_data.profile.ys,"Color",'m');

            addlistener(app.myofibril_data.profile.roi,"ROIMoved",@(src,evt) update_profile(evt));
            app.ExtractProfiles


            function update_profile(evt)
                x_upt = app.myofibril_data.profile.roi.Position(:,1);
                y_upt = app.myofibril_data.profile.roi.Position(:,2);
                cs_upt = spline(x_upt, y_upt);
                xs_upt = linspace(x_upt(1), x_upt(end), 1000);
                ys_upt = ppval(cs_upt, xs_upt);
                app.myofibril_data.profile.xs = linspace(x_upt(1), x_upt(end), 1000);
                app.myofibril_data.profile.ys = ppval(cs_upt, app.myofibril_data.profile.xs);
                app.spline_line.XData = app.myofibril_data.profile.xs;
                app.spline_line.YData = app.myofibril_data.profile.ys;
                app.RefreshDisplay;
                app.ExtractProfiles;
                app.ImageAxes
            end

        end

        % Value changed function: ProminenceEditField
        function ProminenceEditFieldValueChanged(app, event)
            app.RefreshDisplay;
            app.ExtractProfiles;
        end

        % Value changed function: CalibrationumpxEditField
        function CalibrationumpxEditFieldValueChanged(app, event)
            app.RefreshDisplay;
            app.ExtractProfiles;
        end

        % Menu selected function: ExportResultsMenu
        function ExportResultsMenuSelected(app, event)
            [file_string,path_string] = uiputfile2( ...
                {'*.xlsx','Excel file'},'Enter Excel File Name For Analysis Results');

            if (path_string~=0)
                output_file_string = fullfile(path_string,file_string);

                sum_out.image_file = app.myofibril_data.image_file_string;
                sum_out.analyzed_image_number = app.ImageSpinner.Value;
                sum_out.calibration_px_to_um = app.myofibril_data.calibration;

                for i = 1 : numel(app.myofibril_data.profile.sarcomere_lengths)
                    
                    var = sprintf('sarcomere_length_%i_um',i);
                    sum_out.(var) = app.myofibril_data.profile.sarcomere_lengths(i)

                end

                sum_out.mean_sl_um = mean(app.myofibril_data.profile.sarcomere_lengths);
                sum_out.std_sl_um = std(app.myofibril_data.profile.sarcomere_lengths);
                sum_out.sem_sl_um = std(app.myofibril_data.profile.sarcomere_lengths)/...
                                    sqrt(numel(app.myofibril_data.profile.sarcomere_lengths));
                sum_out.fwhm_um = app.myofibril_data.profile.fwhm;

                sarcomere.location_um = app.myofibril_data.profile.sarcomere_location';

                for i = 1 : numel(app.myofibril_data.profile.sarcomere_lengths)
                    var = sprintf('sarcomere_%i_intensity',i);
                    sarcomere.(var) = app.myofibril_data.profile.sarcomere_intensities(i,:)';
                end
                
                sum_profiles.location_um = sarcomere.location_um;
                vars = {'mean_sarcomere_profile','std_sarcomere_profile','sem_sarcomere_profile'};
                for i = 1 : numel(vars)
                sum_profiles.(vars{i}) = app.myofibril_data.profile.(vars{i})';
                end
               
                try 
                    delete(output_file_string)
                end
                
                writetable(struct2table(sum_out),output_file_string,'Sheet','Summary')
                writetable(struct2table(sarcomere),output_file_string,'Sheet','Sarcomere Profiles')
                writetable(struct2table(sum_profiles),output_file_string,'Sheet','Summary Profiles')

                output_file_string = replace(output_file_string,'.xlsx','.myoprof');
                meta_out = app.myofibril_data;
                save(output_file_string,'meta_out')




            end
        end

        % Button pushed function: ScanLinesButton
        function ScanLinesButtonPushed(app, event)
            if  isfield(app.myofibril_data,'profile')
                app.myofibril_data.profile = [];
                cla(app.ImageAxes)
                center_image_with_preserved_aspect_ratio(app.myofibril_data.image_file{1,1}{app.ImageSpinner.Value,1},app.ImageAxes)
                app.RefreshDisplay
            end

            num_of_lines = app.NoofLinesEditField.Value;

            app.myofibril_data.profile.roi = drawline(app.ImageAxes,'LineWidth',1E-32,'MarkerSize',10);
            x_temp = app.myofibril_data.profile.roi.Position(:,1);
            y_temp = app.myofibril_data.profile.roi.Position(:,2);
            m = (y_temp(2) - y_temp(1))/(x_temp(2) - x_temp(1))
            alpha = atan(m)
            d = app.LineSeperationpxEditField.Value;
            x(:,:,1) = x_temp;
            y(:,:,1) = y_temp;
            hold(app.ImageAxes,'on')

            plot(app.ImageAxes,x(:,:,1),y(:,:,1),"Color",'m');
            for i = 2 : num_of_lines
                x(:,:,i) = ((-1)^i)*d*sin(alpha)*cos(alpha) + x_temp;
                y(:,:,i) = ((-1)^i)*d*sin(alpha)*sin(alpha) + y_temp + ((-1)^(i-1))*d;
                plot(app.ImageAxes,x(:,:,i),y(:,:,i),"Color",'m');
            end

            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MyofibrilProfilerUIFigure and hide until all components are created
            app.MyofibrilProfilerUIFigure = uifigure('Visible', 'off');
            app.MyofibrilProfilerUIFigure.Position = [100 100 925 459];
            app.MyofibrilProfilerUIFigure.Name = 'MyofibrilProfiler';

            % Create Menu
            app.Menu = uimenu(app.MyofibrilProfilerUIFigure);
            app.Menu.Text = 'Menu';

            % Create LoadImageMenu
            app.LoadImageMenu = uimenu(app.Menu);
            app.LoadImageMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadImageMenuSelected, true);
            app.LoadImageMenu.Text = 'Load Image';

            % Create ExportResultsMenu
            app.ExportResultsMenu = uimenu(app.Menu);
            app.ExportResultsMenu.MenuSelectedFcn = createCallbackFcn(app, @ExportResultsMenuSelected, true);
            app.ExportResultsMenu.Text = 'Export Results';

            % Create LoadMeasurementMenu
            app.LoadMeasurementMenu = uimenu(app.Menu);
            app.LoadMeasurementMenu.Visible = 'off';
            app.LoadMeasurementMenu.Text = 'Load Measurement';

            % Create DataHandlerPanel
            app.DataHandlerPanel = uipanel(app.MyofibrilProfilerUIFigure);
            app.DataHandlerPanel.Title = 'Data Handler';
            app.DataHandlerPanel.Position = [11 389 431 63];

            % Create ImageFileEditFieldLabel
            app.ImageFileEditFieldLabel = uilabel(app.DataHandlerPanel);
            app.ImageFileEditFieldLabel.HorizontalAlignment = 'right';
            app.ImageFileEditFieldLabel.Position = [4 12 61 22];
            app.ImageFileEditFieldLabel.Text = 'Image File';

            % Create ImageFileEditField
            app.ImageFileEditField = uieditfield(app.DataHandlerPanel, 'text');
            app.ImageFileEditField.Editable = 'off';
            app.ImageFileEditField.FontSize = 10;
            app.ImageFileEditField.Position = [80 12 340 22];

            % Create ImageDisplayPanel
            app.ImageDisplayPanel = uipanel(app.MyofibrilProfilerUIFigure);
            app.ImageDisplayPanel.Title = 'Image Display';
            app.ImageDisplayPanel.Position = [11 15 432 238];

            % Create ImageAxes
            app.ImageAxes = uiaxes(app.ImageDisplayPanel);
            app.ImageAxes.XTick = [];
            app.ImageAxes.YTick = [];
            app.ImageAxes.Box = 'on';
            app.ImageAxes.Position = [8 6 412 204];

            % Create ProfilerControlsPanel
            app.ProfilerControlsPanel = uipanel(app.MyofibrilProfilerUIFigure);
            app.ProfilerControlsPanel.Title = 'Profiler Controls';
            app.ProfilerControlsPanel.Position = [11 324 431 58];

            % Create ImageSpinnerLabel
            app.ImageSpinnerLabel = uilabel(app.ProfilerControlsPanel);
            app.ImageSpinnerLabel.HorizontalAlignment = 'right';
            app.ImageSpinnerLabel.Position = [8 9 48 22];
            app.ImageSpinnerLabel.Text = 'Image #';

            % Create ImageSpinner
            app.ImageSpinner = uispinner(app.ProfilerControlsPanel);
            app.ImageSpinner.ValueChangedFcn = createCallbackFcn(app, @ImageSpinnerValueChanged, true);
            app.ImageSpinner.Position = [64 9 48 22];

            % Create CalibrationumpxEditFieldLabel
            app.CalibrationumpxEditFieldLabel = uilabel(app.ProfilerControlsPanel);
            app.CalibrationumpxEditFieldLabel.HorizontalAlignment = 'right';
            app.CalibrationumpxEditFieldLabel.Position = [239 9 106 22];
            app.CalibrationumpxEditFieldLabel.Text = 'Calibration (um/px)';

            % Create CalibrationumpxEditField
            app.CalibrationumpxEditField = uieditfield(app.ProfilerControlsPanel, 'numeric');
            app.CalibrationumpxEditField.Limits = [0 Inf];
            app.CalibrationumpxEditField.ValueChangedFcn = createCallbackFcn(app, @CalibrationumpxEditFieldValueChanged, true);
            app.CalibrationumpxEditField.Position = [349 9 70 22];
            app.CalibrationumpxEditField.Value = 1;

            % Create ProminenceEditFieldLabel
            app.ProminenceEditFieldLabel = uilabel(app.ProfilerControlsPanel);
            app.ProminenceEditFieldLabel.HorizontalAlignment = 'right';
            app.ProminenceEditFieldLabel.Position = [123 9 72 22];
            app.ProminenceEditFieldLabel.Text = 'Prominence ';

            % Create ProminenceEditField
            app.ProminenceEditField = uieditfield(app.ProfilerControlsPanel, 'numeric');
            app.ProminenceEditField.Limits = [0 1];
            app.ProminenceEditField.ValueChangedFcn = createCallbackFcn(app, @ProminenceEditFieldValueChanged, true);
            app.ProminenceEditField.Position = [202 9 30 22];
            app.ProminenceEditField.Value = 0.5;

            % Create ProfilerPanel
            app.ProfilerPanel = uipanel(app.MyofibrilProfilerUIFigure);
            app.ProfilerPanel.Title = 'Profiler Panel';
            app.ProfilerPanel.Position = [448 15 472 437];

            % Create ProfileIntensity
            app.ProfileIntensity = uiaxes(app.ProfilerPanel);
            title(app.ProfileIntensity, 'Profile Intensity')
            xlabel(app.ProfileIntensity, 'Location (px)')
            ylabel(app.ProfileIntensity, 'Intensity (A.U.)')
            app.ProfileIntensity.Box = 'on';
            app.ProfileIntensity.Position = [13 293 453 115];

            % Create Sarcomeres
            app.Sarcomeres = uiaxes(app.ProfilerPanel);
            title(app.Sarcomeres, 'Sarcomere Intensities')
            xlabel(app.Sarcomeres, 'Location (um)')
            ylabel(app.Sarcomeres, 'Normalized Intensity')
            app.Sarcomeres.Box = 'on';
            app.Sarcomeres.Position = [12 158 453 115];

            % Create SarcomereMean
            app.SarcomereMean = uiaxes(app.ProfilerPanel);
            title(app.SarcomereMean, 'Average Sarcomere Intensity')
            xlabel(app.SarcomereMean, 'Location (um)')
            ylabel(app.SarcomereMean, 'Normalized Intensity')
            app.SarcomereMean.Box = 'on';
            app.SarcomereMean.Position = [11 21 453 115];

            % Create ROIControlsPanel
            app.ROIControlsPanel = uipanel(app.MyofibrilProfilerUIFigure);
            app.ROIControlsPanel.Title = 'ROI Controls';
            app.ROIControlsPanel.Position = [11 259 432 57];

            % Create ScanPointsButton
            app.ScanPointsButton = uibutton(app.ROIControlsPanel, 'push');
            app.ScanPointsButton.ButtonPushedFcn = createCallbackFcn(app, @ScanPointsButtonPushed, true);
            app.ScanPointsButton.Position = [8 7 79 23];
            app.ScanPointsButton.Text = 'Scan Points';

            % Create ScanLinesButton
            app.ScanLinesButton = uibutton(app.ROIControlsPanel, 'push');
            app.ScanLinesButton.ButtonPushedFcn = createCallbackFcn(app, @ScanLinesButtonPushed, true);
            app.ScanLinesButton.Position = [98 7 79 23];
            app.ScanLinesButton.Text = 'Scan Lines';

            % Create LineSeperationpxEditFieldLabel
            app.LineSeperationpxEditFieldLabel = uilabel(app.ROIControlsPanel);
            app.LineSeperationpxEditFieldLabel.HorizontalAlignment = 'center';
            app.LineSeperationpxEditFieldLabel.VerticalAlignment = 'top';
            app.LineSeperationpxEditFieldLabel.Position = [184 6 114 20];
            app.LineSeperationpxEditFieldLabel.Text = 'Line Seperation (px)';

            % Create LineSeperationpxEditField
            app.LineSeperationpxEditField = uieditfield(app.ROIControlsPanel, 'numeric');
            app.LineSeperationpxEditField.Position = [302 7 32 22];
            app.LineSeperationpxEditField.Value = 100;

            % Create ofLinesLabel
            app.ofLinesLabel = uilabel(app.ROIControlsPanel);
            app.ofLinesLabel.HorizontalAlignment = 'right';
            app.ofLinesLabel.Position = [336 8 57 22];
            app.ofLinesLabel.Text = '# of Lines';

            % Create NoofLinesEditField
            app.NoofLinesEditField = uieditfield(app.ROIControlsPanel, 'numeric');
            app.NoofLinesEditField.Limits = [1 Inf];
            app.NoofLinesEditField.ValueDisplayFormat = '%.0f';
            app.NoofLinesEditField.Position = [399 8 29 22];
            app.NoofLinesEditField.Value = 3;

            % Show the figure after all components are created
            app.MyofibrilProfilerUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = myofibril_profiler_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.MyofibrilProfilerUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.MyofibrilProfilerUIFigure)
        end
    end
end