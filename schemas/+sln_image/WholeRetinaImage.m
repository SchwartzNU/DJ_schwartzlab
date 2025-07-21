%{
# annotate the whole retina image
->sln_image.Image
-----
->sln_tissue.Retina
cut_orientation: enum('Dorsal', 'Ventral', 'Nasal', 'Temporal', 'Unknwon')
%}


classdef WholeRetinaImage < dj.Manual
    methods (Static)
        function insert_whole_retina_image(filename, user, scope, channelarr, retina_id, cut)
            try 
                z_scale = 0;
                sln_image.Image.LoadFromFilewithStructuralInput(filename, user, scope, channelarr, z_scale);


                %search the newly added image id
                [folderPath, filepre, fileext] = fileparts(filename);
                query = {};
                query.image_filename = convertStringsToChars(append(filepre, fileext));
                query.folder = convertStringsToChars(folderPath);
                result = fetch(sln_image.Image & query, 'image_id');

                key.image_id = result.image_id;
                key.tissue_id = retina_id;

                query = {};
                query.tissue_id = retina_id;
                result = fetch(sln_tissue.Retina * sln_animal.Eye & query);

                key.animal_id = result.animal_id;
                key.side = result.side;         
                key.cut_orientation = cut;

                C = dj.conn;
                C.startTransaction;
                insert(sln_image.WholeRetinaImage, key);
                C.commitTransaction;

                fprintf('Whole retina image inserted, image id : %d', key.image_id);
                
            catch ME
                fprintf('Inserting Whole retina image failed!');
                rethrow (ME);
            end
        end
    end
end