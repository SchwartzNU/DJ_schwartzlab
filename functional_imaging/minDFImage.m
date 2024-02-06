function minVals = minDFImage(traces, ROIs)
minVals = zeros(ROIs.ImageSize);
for i=1:ROIs.NumObjects
    minVals(ROIs.PixelIdxList{i}) = min(traces(i,:));
end