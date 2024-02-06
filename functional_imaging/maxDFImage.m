function maxVals = maxDFImage(traces, ROIs)
maxVals = zeros(ROIs.ImageSize);
for i=1:ROIs.NumObjects
    maxVals(ROIs.PixelIdxList{i}) = max(traces(i,:));
end