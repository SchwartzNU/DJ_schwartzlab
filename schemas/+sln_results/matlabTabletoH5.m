function [] = matlabTabletoH5(fname,resultTable,folder_key)

if nargin < 3 || isempty(folder_key)
    folder_key = {'file_name', 'dataset_name', 'source_id'};
end

N = height(resultTable); %number of entries

for i=1:N    
    S = table2struct(resultTable(i,:));
    for k=1:length(folder_key)
        folder_location_part{k} = sprintf('%s_%s_',folder_key{k},num2str(S.(folder_key{k})));
    end
    folder_location = strcat(folder_location_part{:});
    folder_location = ['/' folder_location(1:end-1)];
    exportStructToHDF5(S,fname,folder_location);
end