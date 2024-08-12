function D = removeSubsets(C)
%C is a cell array of vectors
ind = [];
for i=1:length(C)
    subset_found = false;
    for j=i+1:length(C)
        if all(ismember(C{j},C{i}))
            subset_found = true;
            break;
        end
    end
    if ~subset_found
        ind = [ind, i];
    end
end

D = C(ind);