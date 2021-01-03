function [ind, dist] = nearestString(s, list)
N = length(list);
D = zeros(N,1);

for i=1:N
    D(i) = wfEdits(s,list{i});
end

[dist, ind] = min(D);
if length(ind)>1
    ind = ind(1);
end

