function ROIs = ROIsFromMask(mask_fname, pixel_thres)
if nargin<2
    pixel_thres = 3;
end

M = imread(mask_fname);
M = M>0;

ROIs = bwconncomp(M,4);
PixList = [];
z=1;
for i=1:ROIs.NumObjects
    currentIDs = ROIs.PixelIdxList{i};
    if length(currentIDs) >= pixel_thres
        PixList{z} = currentIDs;
        z=z+1;
    end
end

ROIs.PixelIdxList = PixList;
ROIs.NumObjects = length(PixList);