%{
#annotate the whole brain images stored as sln_image.Image_05092025
ref_image_id: int unsigned auto_increment
-----
->sln_tissue.BrainSliceBatch
file_name: varchar(128)
folder: varchar(512)
slide_num: tinyint unsigned #which slide is the image taken from
brain_num: tinyint unsigned #same, but brain number of the slice
%}


%todo: need function for inserting this kind of data structure
classdef WholeBrainImage < dj.Manual
    methods(Static)
        function ref_image_id = insert_wb_image(tissue_id, filepath, slide_n, brain_n)
            arguments
                tissue_id 
                filepath 
                slide_n 
                brain_n 
            end
            [key.folder, name, ext] = fileparts(filepath);
            try
                key.slide_num = slide_n;
                key.brain_num = brain_n;
                key.tissue_id = tissue_id;
                %see if the row alreay in database
                query = fetch(sln_image.WholeBrainImage & key, 'file_name');
                if (~isempty(query))
                   warning('Whole brain image already in the database! %s', query.file_name);

                   ref_image_id = query.ref_image_id;
                   return;
                end
                %continue build insert struct if not
                key.file_name = append(name, ext);

                %try insert
                C = dj.conn;
                C.startTransaction;
                insert(sln_image.WholeBrainImage, key);
                C.commitTransaction;

                fprintf('Inserting success!\n');
                disp(key);


                %return the inserted ref_id
                inserted = fetch(sln_image.WholeBrainImage & key);
                ref_image_id = inserted.ref_image_id;

            catch ME
                if (exist('C', 'var'))
                    C.cancelTransaction;
                end              
                rethrow(ME)

            end
        end

        function prior_s = count_slice_before(ref_image_id)
            % TO DO
        end
    end
end