function loadFolderOfCuratedRigImages(folder_name)
if nargin<1
    folder_name = uigetdir('','Select folder where images are located');
end
if ~exist(folder_name,'dir')
    error('Please specify a valid folder.');
end
waitfor(sln_image.ImageLoader_contentOnly); %assigns variable loaderPrefs
loaderPrefs = evalin('base','loaderPrefs');
evalin('base','clear loaderPrefs');
if isempty(loaderPrefs)
    fprintf('No images loaded\n');
    return;
end
D_base = dir(folder_name);
cell_names = {D_base.names};
cell_names = cell_names(~startsWith(cell_names,'.'));
fprintf('Attempting to load %d cell images.\n', length(cell_names));
for i=1:length(cell_names)
    cur_cellname = cell_names{i};
    match = proj(sln_symphony.ExperimentRetina,'source_id->retina_id','*') * ...
        sln_animal.Eye * ...
        sln_cell.Cell * ...
        sln_cell.CellName & ...
        sprintf('cell_name="%s"',cur_cellname);
    if match.count == 1
        match_struct = fetch(match,'*');
        err = false;
        if contains(cur_cellname, 'Ac')
            scope = 'RigA';            
        elseif contains(cur_cellname, 'Bc')
            scope = 'RigB';
        else
            err = true;
            fprintf('Error for cell %s: Cannot determine which rig.\n', cur_cellname);
        end
        
        user = match_struct.experimenter;
        if strcmp(match_struct.side, 'Left')
            tissue_type = 'L eye';
        elseif strcmp(match_struct.side, 'Right')
            tissue_type = 'R eye';
        else
            err = true;
            fprintf('Error for cell %s: Cannot determine which eye.\n', cur_cellname);
        end

        z_scale = []; %should be read automatically from images

        if ~err
            D = dir([folder_name filesep cur_cellname]);
            excluded = contains(names,'_cell.tif') | ...
                contains(names,'_skel.tif') | ...
                contains(names,'_maxProj.tif') | ...
                contains(names,'_chat.tif') |  ...
                contains(names,'_mask.tif') |  ...
                contains(names,'Composite') | ...
                containts(folders,'parts');

            D = D(~excluded);

            for j=1:length(D)
                file_info = D(j);
                if ~sln_image.Image.inDB(file_info)
                    fprintf('Loading %s\n', file_info.name);
                    fname = [file_info.folder filesep file_info.name];
                    if strcmp(loaderPrefs.ch2, ' ')
                        if contains(file_info.name, '_stitched')
                            sln_image.Image.loadFromStitchedFile(fname, scope, user, z_scale, ...
                                loaderPrefs.ch1);
                        else
                            sln_image.Image.loadFromFile(fname, scope, user, z_scale, ...
                                loaderPrefs.ch1);
                        end
                    elseif strcmp(loaderPrefs.ch3, ' ')
                        if contains(file_info.name, '_stitched')
                            sln_image.Image.loadFromStitchedFile(fname, scope, user, z_scale, ...
                                loaderPrefs.ch1, loaderPrefs.ch2);
                        else
                            sln_image.Image.loadFromFile(fname, scope, user, .z_scale, ...
                                loaderPrefs.ch1, loaderPrefs.ch2);
                        end
                    elseif strcmp(loaderPrefs.ch4, ' ')
                        if contains(file_info.name, '_stitched')
                            sln_image.Image.loadFromStitchedFile(fname, scope, user, z_scale, ...
                                loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3);
                        else
                            sln_image.Image.loadFromFile(fname, scope, user, z_scale, ...
                                loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3);
                        end
                    else
                        if contains(file_info.name, '_stitched')
                            sln_image.Image.loadFromStitchedFile(fname, cope, user, z_scale, ...
                                loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3, loaderPrefs.ch4);
                        else
                            sln_image.Image.loadFromFile(fname, scope, user, z_scale, ...
                                loaderPrefs.ch1, loaderPrefs.ch2, loaderPrefs.ch3, loaderPrefs.ch4);
                        end
                    end
                    match = sln_image.Image.get_db_match(file_info); %get image we just loaded
                    if match.exists
                        match.assignToTissue(match_struct.animal_id, tissue_type);
                    end
                else
                    fprintf('Skipping %s. Already in database.\n', file_info.name);
                end
            end
        end

    else
        fprintf('Failed to find a matching cell in the database for %s\n', cur_cellname);
    end
end

