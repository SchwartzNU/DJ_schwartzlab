%{
#Store swc files of axons of RGC axon terminals in brain that are traced, can be multiple files
->sln_image.AxonInBrain
---
trace_coordinates: blob@raw #trees of the traced axon, is cell array, each cell is 1 swc file
%}
classdef AxonMorphFile < dj.Manual

    methods (Static)
        function insert_new_swc(im_id, new_folder)
            arguments
                im_id
                new_folder = {};
            end
            try
                key.image_id = im_id;
                if (isempty(new_folder))
                    %the folder is the same one in the database

                    im_data = fetch(sln_image.Image & key, 'folder');
                    new_folder = im_data.folder;
                end
                files = dir(new_folder);
                files = files(~[files.isdir]);
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
                %inserting
                key.trace_coordinates = swc_load;
                insert(sln_image.AxonMorphFile, key);

                fprintf('.swc files uploaded for image folder: %s\n', new_folder);
                fprintf('Total swc files: %d\n', i);
            catch ME
                rethrow (ME);
            end

        end
    end
end