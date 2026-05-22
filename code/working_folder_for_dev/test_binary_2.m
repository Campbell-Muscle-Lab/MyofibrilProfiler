function test_binary



im = imread("myomesin.png");


bin_im = imbinarize(im,'adaptive',Sensitivity=0.35);
bin_im = bwareaopen(bin_im, 200);
bin_im = imfill(bin_im, 'holes');

% bin_im = imcrop(bin_im,[800 700 1000 1000]);


lab_im = bwlabel(bin_im);

s = regionprops(lab_im, 'Centroid','Area','ConvexHull', ...
    'ConvexArea','PixelList','Orientation','Image');
figure(1);
clf
subplot(1,2,1)
imshow(bin_im)
% list = 1:50;
EP = zeros(2*numel([s.Area]),4);
n = numel([s.Area]);
for i = 1 : numel([s.Area])
% i = list(k);
or = s(i).Orientation;
center = s(i).Centroid;
xy_or = s(i).PixelList;

stripe_blob = s(i).Image;
im_rot = imrotate(lab_im, -or);

stats = regionprops(im_rot,'PixelList');
xy = stats(i).PixelList;


hold on
% plot(xy_or(:,1),xy_or(:,2),'+')
set(gca,"YDir","reverse")
sp = csaps(xy(:,1),xy(:,2),0.1);

x = xy_or(:,1);
y = xy_or(:,2);

% center(1) = size(bin_im,1)/2
% center(2) = size(bin_im,2)/2

x_rel = x - center(1);
y_rel = y - center(2);

R = [cosd(or) -sind(or); sind(or) cosd(or)];
rotated_coords = R * [x_rel y_rel]';


x_new = rotated_coords(1,:) + center(1);
y_new = rotated_coords(2,:) + center(2);

% plot(x_new, y_new, 'r+');
sp = csaps(x_new,y_new,0.1);
points = fnplt(sp);

x_rel = points(1,:)- center(1);
y_rel = points(2,:) - center(2);

R = [cosd(-or) -sind(-or); sind(-or) cosd(-or)];
rotated_coords = R * [x_rel; y_rel];


splines{i}.x = rotated_coords(1,:) + center(1);
splines{i}.y = rotated_coords(2,:) + center(2);

plot(splines{i}.x,splines{i}.y,'b')

x = splines{i}.x;
y = splines{i}.y;

Start(i,:) = [x(1),   y(1)];
End(i,:)   = [x(end), y(end)];

end

utku =6
tic
D = pdist2(End, Start)
toc

D(1:numel([s.Area])+1:end) = Inf;

maxDist = 150;

[iEnd, jStart] = find(D < maxDist);

distances = D(sub2ind(size(D), iEnd, jStart));

T = table(iEnd, jStart, distances, ...
    'VariableNames', {'EndOfSpline','StartOfSpline','Distance'});

T = sortrows(T, 'Distance');

% Keep only one connection per end and one connection per start
usedEnds = false(n,1);
usedStarts = false(n,1);

keep = false(height(T),1);

for r = 1:height(T)

    i = T.EndOfSpline(r);
    j = T.StartOfSpline(r);

    if ~usedEnds(i) && ~usedStarts(j)
        keep(r) = true;

        usedEnds(i) = true;
        usedStarts(j) = true;
    end
end

endToStartTable = T(keep,:);

for r = 1:height(endToStartTable)
    i = endToStartTable.EndOfSpline(r);
    j = endToStartTable.StartOfSpline(r);

    p1 = End(i,:);
    p2 = Start(j,:);
    hold on
    plot([p1(1) p2(1)], [p1(2) p2(2)], 'r-', 'LineWidth', 2)
end

% plot(Start(:,1), Start(:,2), 'go', 'MarkerSize', 8, 'LineWidth', 2)
% plot(End(:,1), End(:,2), 'ro', 'MarkerSize', 8, 'LineWidth', 2)

return
maxDist = 30;

adjacentPairs = [];

for i = 1:size(EP,1)

    neighbors = find(D(i,:) < maxDist & D(i,:) > 0);

    for j = neighbors

        s1 = EP(i,3);
        s2 = EP(j,3);

        % skip same spline
        if s1 == s2
            continue
        end

        adjacentPairs = [adjacentPairs;
            s1 EP(i,4) s2 EP(j,4) D(i,j)];
    end
end

adjacentPairs = unique(adjacentPairs,'rows');

adjacentTable = array2table(adjacentPairs,...
    'VariableNames',...
    {'Spline1','End1','Spline2','End2','Distance'})


for r = 1:size(adjacentPairs,1)

    s1 = adjacentPairs(r,1);
    e1 = adjacentPairs(r,2);

    s2 = adjacentPairs(r,3);
    e2 = adjacentPairs(r,4);

    % endpoint coordinates
    if e1 == 1
        p1 = [splines{s1}.x(1), splines{s1}.y(1)];
    else
        p1 = [splines{s1}.x(end), splines{s1}.y(end)];
    end

    if e2 == 1
        p2 = [splines{s2}.x(1), splines{s2}.y(1)];
    else
        p2 = [splines{s2}.x(end), splines{s2}.y(end)];
    end

    plot([p1(1) p2(1)], ...
         [p1(2) p2(2)], ...
         'r-', ...
         'LineWidth',2)
end

return
y = fnval(sp,xy(:,1));
x = xy(:,1);
subplot(2,1,1)
% imshow(stripe_blob)
hold on

center = [mean(x),mean(y)];

x_rel = x - center(1);
y_rel = y - center(2);


R = [cosd(-or) -sind(-or); sind(-or) cosd(-or)];
rotated_coords = R * [x_rel y_rel]';


x_new = rotated_coords(1,:) + center(1);
y_new = rotated_coords(2,:) + center(2);

plot(x_new, y_new, 'r-', 'LineWidth', 2);

% segments = diff(y, 1, 2)
% c = [xy(:,1),y]'
% d = [cosd(45), sind(45); -sind(45), cosd(45)] * c
% plot(d(1,:), d(2,:), 'r');

end