function test_binary



im = imread("myomesin.png");

% im = imcrop(im,[1050 1050 500 200]);

bin_im = imbinarize(im,'adaptive',Sensitivity=0.35);
bin_im = bwareaopen(bin_im, 20);
bin_im = imfill(bin_im, 'holes');




lab_im = bwlabel(bin_im);



s = regionprops(lab_im, 'Centroid','Area','ConvexHull', ...
    'ConvexArea','PixelList','Orientation','Image');

boundaries = bwboundaries(lab_im);

i = 100;
center = s(i).Centroid;
coord = boundaries{i};
or = s(i).Orientation;

stripe_blob = s(i).Image;
im_rot = imrotate(stripe_blob, -or);

stats = regionprops(im_rot,'PixelList');
xy = stats.PixelList

figure(1);
clf
subplot(2,1,1)
imshow(im_rot)
subplot(2,1,2)
hold on
plot(xy(:,1),xy(:,2),'+')
set(gca,"YDir","reverse")
p = linspace(0,1,10);
for i = 1:10
sp = csaps(xy(:,1),xy(:,2),p(i));
fnplt(sp);
end


end