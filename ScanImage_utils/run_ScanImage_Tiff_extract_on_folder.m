function run_ScanImage_Tiff_extract_on_folder(folder_path)
    tiff_files = dir([folder_path, filesep, '*.tif']);
    for i = 1:length(tiff_files)
        try
            file_path = [folder_path, filesep, tiff_files(i).name];
            fprintf('Processing: %s \n', file_path);
            extractScanimageTiffMetadata(file_path);
        catch
            warning('%s might not be ScanImage Tiff \n', tiff_files(i).name);
        end
    end

end