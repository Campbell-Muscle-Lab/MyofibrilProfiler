function test_binary_3



im = imread("myomesin.png");


bin_im = imbinarize(im,'adaptive',Sensitivity=0.35);
bin_im = bwareaopen(bin_im, 20);
BW = imfill(bin_im, 'holes');



CC = bwconncomp(BW);
stats = regionprops(CC, 'Area','Orientation','MajorAxisLength','MinorAxisLength','BoundingBox');

BWout = false(size(BW));
crop_fig = 0;
for k = 1:CC.NumObjects

    if stats(k).Area < 5
        continue
    end

    theta = stats(k).Orientation;
    % L = round(stats(k).MajorAxisLength);
    L = min(stats(k).MinorAxisLength, stats(k).MajorAxisLength)
    se = strel('line', 3*L, theta);

    bb = stats(k).BoundingBox;
    pad = stats(k).MinorAxisLength + 3;

    x1 = max(1, floor(bb(1)) - pad);
    y1 = max(1, floor(bb(2)) - pad);
    x2 = min(size(BW,2), ceil(bb(1)+bb(3)) + pad);
    y2 = min(size(BW,1), ceil(bb(2)+bb(4)) + pad);

    crop = BW(y1:y2, x1:x2);
    st = regionprops(crop);
    st.Centroid;
    cropClosed = imclose(crop, se);
    % cropClosed = imopen(crop,se);
    if crop_fig && ~mod(k,5)
    figure(2)
    clf
    imshowpair(crop, cropClosed)
    pause(1)
    end
    BWout(y1:y2, x1:x2) = BWout(y1:y2, x1:x2) | cropClosed;
end

figure(1)
clf
imshowpair(BW, BWout, 'montage')




return
plot(xy_or(:,1),xy_or(:,2),'+')
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

plot(x_new, y_new, 'r+');
sp = csaps(x_new,y_new,0.1);
points = fnplt(sp);

x_rel = points(1,:)- center(1);
y_rel = points(2,:) - center(2);

R = [cosd(-or) -sind(-or); sind(-or) cosd(-or)];
rotated_coords = R * [x_rel; y_rel];


x_new = rotated_coords(1,:) + center(1);
y_new = rotated_coords(2,:) + center(2);

plot(x_new,y_new,'b')




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