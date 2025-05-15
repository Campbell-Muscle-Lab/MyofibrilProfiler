function test(varargin)

p = inputParser;
addOptional(p, 'image_file_string', '../data/heart3003.nd2');
addOptional(p, 'min_rel_peak_prominence', 0.5);
addOptional(p, 'n_profile_points', 1000);

parse(p, varargin{:});
p = p.Results;

% Code

% Some marker points for spline
x = [920, 962, 999, 1025, 1073, 1116, 1159, 1199]
y = [1007, 1086, 1173, 1247, 1331, 1426, 1505, 1579];

% Fit the spline
cs = spline(x, y);
xs = linspace(x(1), x(end), 1000);
ys = ppval(cs, xs);

% Open the image
d = bfopen(p.image_file_string)

% Pull out first image
ds1 = d{1,1}{1,1};

% Extract profile along the spline
im_profile = improfile(ds1, xs, ys);
x_profile = 1:numel(im_profile);

% Find peaks
[pks, locs] = findpeaks(-im_profile, ...
    'MinPeakProminence', p.min_rel_peak_prominence * range(im_profile))

% Find sarcomere profiles
x_sarc_profile = linspace(0, 1, p.n_profile_points);

% Pull off profiles and interpolate
no_of_sarcomeres = numel(locs) - 1;
for i = 1 : no_of_sarcomeres
    profile_indices = locs(i) : locs(i+1);
    x_temp = normalize(profile_indices, 'range');
    y_sarc_profile(i, :) = interp1(x_temp, im_profile(profile_indices), ...
        x_sarc_profile);
end

figure(1);
clf;

n_rows = 4;
n_cols = 2;

subplot(n_rows, n_cols, 1);
imagesc(ds1);
hold on;
plot(x, y, 'k-o')
plot(xs, ys,'m-')

subplot(n_rows, n_cols, n_cols+1);
hold on;
plot(im_profile, 'b-');
plot(locs, -pks, 'go')

subplot(n_rows, n_cols, (2*n_cols)+1);
hold on;
plot(x_sarc_profile, y_sarc_profile);

subplot(n_rows, n_cols, (3*n_cols)+1);
hold on;
shadedErrorBar(x_sarc_profile, y_sarc_profile, {@mean, @std});



