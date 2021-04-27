function outputStruct = distributeAndOrder(keyList, listStruct, varargin)
%documentation!
outputStruct = [];

listNames = fieldnames(listStruct);
N_lists = length(listNames);
for i=1:N_lists
    if length(listStruct.(listNames{i})) ~= length(keyList)
        disp('Error: all lists must be the same length');
        return;
    end
end

if iscell(keyList)
    listType = 'cellArray';    
elseif isnumeric(keyList)
    listType = 'vec';    
else
    disp('Error: first argument needs to be a cell array of strings or a numeric vector');
    return;
end

%TODO deal with binnnig stuff here with varargin
U = sort(unique(keyList));
N = length(U);

outputStruct.keyVals = U;
outputStruct.key_N = zeros(N,1);
outputStruct.key_ind = false(N,length(keyList));

for n=1:N_lists
    curName = listNames{n};
    outputStruct.([curName '_mean']) = zeros(N,1);
    outputStruct.([curName '_sem']) = zeros(N,1);
    outputStruct.([curName '_sd']) = zeros(N,1);
    outputStruct.([curName '_N_noNaN']) = zeros(N,1);    
end

for i=1:N
    if strcmp(listType, 'cellArray')
        ind = strcmp(keyList, U{i});               
    else
        ind = keyList == U(i);
    end
    outputStruct.key_N(i) = sum(ind);     
    outputStruct.key_ind(i,:) = ind;
    
    for n=1:N_lists
       curName = listNames{n};
       curList = listStruct.(curName);
       vals = curList(ind);
       N_nonan = sum(~isnan(vals));
       outputStruct.([curName '_mean'])(i) = mean(vals);
       outputStruct.([curName '_N_noNaN'])(i) = N_nonan;
       sd = nanstd(vals);
       outputStruct.([curName '_sd'])(i) = sd;
       outputStruct.([curName '_sem'])(i) = sd / sqrt(N_nonan-1);       
    end
end
