I = imread('myomesin.png');
if size(I,3) == 3
    I = rgb2gray(I);
end

BW = I > 0;
BW = bwareaopen(BW, 5);

%% Step 1: directional closing

BWclosed = BW;

angles = -55:5:-25;
lengths = 7:2:25;

for L = lengths
    temp = BWclosed;

    for theta = angles
        se = strel('line', L, theta);
        temp = temp | imclose(BWclosed, se);
    end

    BWclosed = temp;
end

BWclosed = bwareaopen(BWclosed, 10);

%% Step 2: skeletonize

Skel = bwskel(BWclosed);

%% Step 3: bridge nearby endpoints

EP = bwmorph(Skel, 'endpoints');
[y, x] = find(EP);

maxDist = 22;        % max endpoint gap to bridge
angleTol = 25;       % allowed angle difference
stripeAngle = -40;   % approximate stripe direction

SkelBridge = Skel;

for i = 1:numel(x)

    for j = i+1:numel(x)

        dx = x(j) - x(i);
        dy = y(j) - y(i);
        d = hypot(dx, dy);

        if d < 3 || d > maxDist
            continue
        end

        bridgeAngle = atan2d(dy, dx);

        % Normalize angle difference to [-90, 90]
        angleDiff = abs(mod(bridgeAngle - stripeAngle + 90, 180) - 90);

        if angleDiff < angleTol

            rr = round(linspace(y(i), y(j), round(d)*2));
            cc = round(linspace(x(i), x(j), round(d)*2));

            valid = rr >= 1 & rr <= size(Skel,1) & ...
                    cc >= 1 & cc <= size(Skel,2);

            ind = sub2ind(size(Skel), rr(valid), cc(valid));
            SkelBridge(ind) = true;
        end
    end
end

%% Step 4: clean skeleton slightly

SkelBridge = bwmorph(SkelBridge, 'thin', Inf);
SkelBridge = bwmorph(SkelBridge, 'spur', 2);

%% Step 5: rebuild blobs with similar width using line dilation

targetWidth = 18;

BWuniform = false(size(BW));

for theta = angles
    se = strel('line', targetWidth, theta);
    BWuniform = BWuniform | imdilate(SkelBridge, se);
end

BWuniform = imfill(BWuniform, 'holes');
BWuniform = bwareaopen(BWuniform, 20);

%% Display

figure
imshowpair(BW, BWclosed, 'montage')
title('Original | Directionally closed')

figure
imshowpair(Skel, SkelBridge, 'montage')
title('Skeleton | Endpoint-bridged skeleton')

figure
imshowpair(BW, BWuniform, 'montage')
title('Original | Final uniform-width connected blobs')