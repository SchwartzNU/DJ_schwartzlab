function D = getLargerSet(C)
%C is a cell array of vectors
ind = [];
rmList = [];
for i=1:length(C)
    testL = [];
    L = length(C{i});
    for j=1:length(C)
        if i~=j
            if any(ismember(C{j},C{i}))
                if length(C{j}) > L
                    testL = [testL, j];
                elseif length(C{j}) == L
                    rmList = [rmList j];
                end

            end
        end
    end
    if ~isempty(testL)
        [~, maxInd] = max(testL);
        ind = [ind, testL(maxInd)];
    else
        ind = [ind, i];
    end

end

ind = unique(ind);
ind = setdiff(ind, rmList);
curLen = length(ind);
if curLen < length(C)
    D = getLargerSet(C(ind));
else
    D = C;
end