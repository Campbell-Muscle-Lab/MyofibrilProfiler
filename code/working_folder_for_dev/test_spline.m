function test_spline

profile = load('profile.mat','-mat');

profile = profile.im_profile';

profile = rescale(profile)

[~,peaks] = findpeaks(profile,'MinPeakDistance',25);
[~,dips] = findpeaks(-profile+1,'MinPeakDistance',50);

figure(1)
clf
subplot(3,1,1)
hold on
plot(profile,'k')
plot(peaks,profile(peaks),'ro','MarkerSize',10)
plot(dips,profile(dips),'ms','MarkerSize',10)


for i = 1 : numel(peaks)-1

x_profile = [];
prof = [];

x_profile = peaks(i):peaks(i+1);

dip = dips(dips>peaks(i) & dips<peaks(i+1));
dip_ix = find(dip == x_profile);
prof = -profile(x_profile) + 1;

fwhm_ix(i,1) = find(prof >= 0.5*(prof(dip_ix) + prof(1)),1,'first');
fwhm_ix(i,2) = find(prof >= 0.5*(prof(dip_ix) + prof(end)),1,'last');
fwhm(i) = x_profile(fwhm_ix(i,2)) - x_profile(fwhm_ix(i,1));

subplot(3,1,2)
hold on
plot(x_profile,prof)
plot(x_profile(dip_ix),prof(dip_ix),'s')
plot(x_profile(fwhm_ix(i,:)),prof(fwhm_ix(i,:)),'o')

end
rng default; % For reproducibility

[idx,C] = kmeans(fwhm',2)

group_1 = fwhm(idx==1)
group_2 = fwhm(idx==2)

fwhm_ix;


for i = 1:size(fwhm_ix,1)


    x_profile = [];
    prof = [];

    x_profile = peaks(i):peaks(i+1);
    prof = -profile(x_profile) + 1;

    subplot(3,1,3)
    hold on
    plot(x_profile,prof)
    
    if idx(i) == 1
        col = [1 0 0];
    else
        col = [0 0 1];
    end

    x = linspace(x_profile(fwhm_ix(i,1)),x_profile(fwhm_ix(i,2)));
    y = linspace(prof(fwhm_ix(i,1)),prof(fwhm_ix(i,2)));
    plot(x,y,':','color',col)

    fwhm(i)


end

[h,p,ci,stats] = ttest2(group_1,group_2)
end