function [] = toH5(fname,resultTable)
primary_key = resultTable.header.primaryKey();

S = fetch(resultTable,'*');
N = length(S); %number of entries

for i=1:N    
    for k=1:length(primary_key)
        folder_location_part{k} = sprintf('%s_%s_',primary_key{k},num2str(S(i).(primary_key{k})));
    end
    folder_location = strcat(folder_location_part{:});
    folder_location = ['/' folder_location(1:end-1)];
    exportStructToHDF5(S(i),fname,folder_location);
end

