function [] = loadFolder(folder_name)
if nargin<1
    folder_name = uigetdir('','Select folder where images are located');
end
if ~exist(folder_name,'dir')
    error('Please specify a valid folder.');
end
waitfor(sln_image.ImageLoader); %assigns variable loaderPrefs
loaderPrefs = evalin('base','loaderPrefs');
evalin('base','clear loaderPrefs');
if isempty(loaderPrefs)
    fprintf('No images loaded\n');
    return;
end

switch loaderPrefs.image_type
    case '.tif'
        D = dir([folder_name filesep '**' filesep '*.tif']);
    case '.nd2'
        D = dir([folder_name filesep '**' filesep '*.nd2']);
    case 'both'
        D_tif = dir([folder_name filesep '**' filesep '*.tif']);
        D_nd2 = dir([folder_name filesep '**' filesep '*.nd2']);
        D = [D_tif; D_nd2];
end

for i=1:length(D)
    file_info = D(i);    
    if ~sln_image.Image.inDB(file_info)
        fprintf('Loading %s\n', file_info.name);
        fname = [file_info.folder filesep file_info.name];
        if strcmp(loaderPrefs.ch2, ' ')
            if contains(file_info.name, '_stitched')
                sln_image.Image.loadFromStitchedFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                    loaderPrefs.ch1);
            else
                sln_image.Image.loadFromFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                    loaderPrefs.ch1);
            end
        elseif strcmp(loaderPrefs.ch3, ' ')
            if contains(file_info.name, '_stitched')
                sln_image.Image.loadFromStitchedFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                    loaderPrefs.ch1, loaderPrefs.ch2);
            else
                sln_image.Image.loadFromFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                    loaderPrefs.ch1, loaderPrefs.ch2);
            end
        elseif strcmp(loaderPrefs.ch4, ' ')
            if contains(file_info.name, '_stitched')
                sln_image.Image.loadFromStitchedFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                    loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3);
            else
                sln_image.Image.loadFromFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                    loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3);
            end
        else
            if contains(file_info.name, '_stitched')
                sln_image.Image.loadFromStitchedFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                    loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3, loaderPrefs.ch4);
            else
                sln_image.Image.loadFromFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                    loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3, loaderPrefs.ch4);
            end
        end
        match = sln_image.Image.get_db_match(file_info); %get image we just loaded
        if match.exists
            match.assignToTissue(loaderPrefs.animal_id, loaderPrefs.tissue_type);
        end
    else
        fprintf('Skipping %s. Already in database.\n', file_info.name);
    end
end
