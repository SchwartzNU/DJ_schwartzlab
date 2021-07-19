function [] = h5Export(pipeline, exportState, resultsStruct, overwrite)
if nargin < 4
    overwrite = true;
end

saveFolder = [getenv('pipelines_folder'), pipeline, filesep, 'h5' filesep];
saveFolder = strrep(saveFolder, '~/', getenv('home_dir'));%hdf5write cannot deal with ~!!!
if ~exist(saveFolder,'dir')
    fprintf('Making new h5 folder for pipeline %s\n', pipeline);
    mkdir(saveFolder);
end

N = length(resultsStruct);
old_filename = '';
for i=1:N
    fprintf('Exporting item %d of %d\n', i, N);    
    [filename, datasetname, variablenames] = parseExportSettings(exportState, resultsStruct(i));
    fields = fieldnames(resultsStruct(i).result);
    fullName = [saveFolder, filename];
    %create the file
    if ~exist(fullName, 'file')
        fid = fopen(fullName, 'w');
        fclose(fid);        
    else
        if overwrite
            if ~strcmp(old_filename, filename)
                %only overwrite once per file
                delete(fullName); %delete old file
                fid = fopen(fullName, 'w');
                fclose(fid);
                old_filename = filename;
            end
        end        
    end
    
    for f=1:length(variablenames)
        for g=1:length(fields)
            if endsWith(variablenames{f}, fields{g})
                curField = fields{g};
            end
        end
        curVal = resultsStruct(i).result.(curField);
        if islogical(curVal)
            curVal = double(curVal);
        end
        try
            hdf5write(fullName, ['/' datasetname '/' variablenames{f}], ...
                curVal, 'WriteMode', 'append');
        catch
            fprintf('Error writing hdf5 file %s\n', fullName);
            return;
        end
    end
end
disp('Export complete');
