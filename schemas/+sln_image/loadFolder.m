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
%add the "link_to" files which have .nd2.txt or .tif.txt extensions
D_link_nd2 = dir([folder_name filesep '**' filesep '*.nd2.txt']);
D_link_tif = dir([folder_name filesep '**' filesep '*.tif.txt']);

D = [D; D_link_nd2; D_link_tif];

%get rid of some files we don't want to try to import
names = {D.name};
folders = {D.folder};
excluded = contains(names,'_cell.tif') | ...
    contains(names,'_skel.tif') | ...
    contains(names,'_maxProj.tif') | ...
    contains(names,'_chat.tif') |  ...
    contains(names,'_mask.tif') |  ...
    contains(names,'Composite') | ...
    contains(folders,'parts');

D = D(~excluded);

for i=1:length(D)
    file_info = D(i);
    if startsWith(file_info.name, 'link_to_')
        im_name = extractAfter(file_info.name,'link_to_');
        im_name = extractBefore(im_name, '.txt');
        thisImage = sln_image.Image & ...
            sprintf('image_filename="%s"', im_name) & ...
            sprintf('user_name="%s"', loaderPrefs.user) & ...
            sprintf('scope_name="%s"', loaderPrefs.scope);
        if thisImage.count == 1
            fprintf('linking an additional cell to image %s\n', im_name);
            [match_found, this_unid] = thisImage.assignToTissue(loaderPrefs.animal_id, loaderPrefs.tissue_type);           
            if ~match_found
                fprintf('writing cell_unid file for cell %d\n', this_unid);
                D(i).folder
                f = fopen([D(i).folder filesep 'cell_id_' num2str(this_unid) '.txt'],'w');
                fwrite(f,this_unid);
                fclose(f);
            end            
        end        
    else
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
end
