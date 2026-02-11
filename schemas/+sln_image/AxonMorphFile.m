%{
#Store swc files of axons of RGC axon terminals in brain that are traced, can be multiple files
->sln_image.AxonInBrain
---
trace_coordinates: blob@raw #trees of the traced axon, is cell array, each cell is 1 swc file
axon_axis: blob@raw #a starting point plus the slope and intercept of the axis that goes through the axon
%}

classdef AxonMorphFile < dj.Manual

    methods (Static)
        function insert_new_morphfile(im_id, new_folder) %image DJID and the folder of the image (if changed from original image upload)
            arguments
                im_id
                new_folder = {};
            end
            try
                key.image_id = im_id;
                if (isempty(new_folder))
                    %the folder is the same one in the database
                    
                    im_data = fetch(sln_image.Image & key, 'folder');
                    fprintf('Using deault folder %s\n', im_data.folder);
                    new_folder = im_data.folder;
                end
                files = get_files_of_folder(new_folder);

                %part 1: upload swc file into coordinate
                indexes = find(endsWith({files.name}, 'swc'));
                swc_files =files(indexes);
                swc_load = cell(1, numel(swc_files));
                for i = 1:numel(swc_files)
                    filename = fullfile(new_folder, swc_files(i).name);
                    fid = fopen(filename, 'r', 'n', 'UTF-8');
                    assert(fid ~= -1, 'Cannot open file: %s', filename);

                    % textscan is much more robust than sscanf/fgetl
                    C = textscan(fid, ...
                        '%f %f %f %f %f %f %f', ...
                        'CommentStyle', '#', ...
                        'Delimiter', {' ', '\t'}, ...
                        'MultipleDelimsAsOne', true, ...
                        'CollectOutput', true);

                    fclose(fid);

                    if isempty(C{1})
                        error('No valid SWC data detected');
                    end

                    data = C{1};
                    swc.id     = data(:,1);
                    swc.type   = data(:,2);
                    swc.x      = data(:,3);
                    swc.y      = data(:,4);
                    swc.z      = data(:,5);
                    %swc.r      = data(:,6);
                    swc.parent = data(:,7);
                    swc_load{i} = swc; % Store the SWC structure in the cell array
                end

                %part 2 uploading the axis file, manually labeled from axonskwer app
                idx = strcmp('Orthogonal.mat', {files.name});
                if ~sum(idx)
                    error('Cannot find axon axis in folder: %s!\n', new_folder);
                end

                ax_f = load(fullfile(new_folder, files(idx).name));
                %inserting
                key.trace_coordinates = swc_load;
                key.axon_axis = ax_f.result;
                insert(sln_image.AxonMorphFile, key);

                fprintf('.swc files uploaded for image folder: %s\n', new_folder);
                fprintf('Total swc files: %d\n', i);
            catch ME
                rethrow (ME);
            end

        end
        
        function coords= get_trace_coords(image_id)
            %combine all swc file into 1 matrix?
            query = sprintf('image_id  = %d', image_id);
            data = fetch(sln_image.AxonMorphFile & query, '*');

            coords = [];
            for i = 1:numel(data.trace_coordinates)
                x = data.trace_coordinates{i}.x;
                y = data.trace_coordinates{i}.y;
                z = data.trace_coordinates{i}.z;

                coords = [coords; [x, y, z]]; % Concatenate coordinates from each SWC file

            end
        end
    end
end