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
            sln_image.Image.loadFromFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                loaderPrefs.ch1);
        elseif strcmp(loaderPrefs.ch3, ' ')
            sln_image.Image.loadFromFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                loaderPrefs.ch1, loaderPrefs.ch2);
        elseif strcmp(loaderPrefs.ch4, ' ')
             sln_image.Image.loadFromFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3);
        else
            sln_image.Image.loadFromFile(fname, loaderPrefs.scope, loaderPrefs.user, loaderPrefs.z_scale, ...
                loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3, loaderPrefs.ch4);
        end
    end
end
