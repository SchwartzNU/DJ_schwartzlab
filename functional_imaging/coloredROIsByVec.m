function M = coloredROIsByVec(vec, ROIs)
M = ones(ROIs.ImageSize) .* nan;
for i=1:ROIs.NumObjects
    M(ROIs.PixelIdxList{i}) = vec(i);
end