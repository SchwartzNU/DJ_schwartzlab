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
        function ref_image_id = insert_wb_image(tissue_id, filepath, slide_n, brain_n, mdp1, mdp2)
            arguments
                tissue_id 
                filepath 
                slide_n 
                brain_n 
                mdp1 = NaN;
                mdp2 = NaN;
            end
            [key.folder, name, ext] = fileparts(filepath);
            try
                key.file_name = append(name, ext);
                key.tissue_id = tissue_id;
                %see if the row alreay in database
                query = sln_image.WholeBrainImage & key;
                if (exists(query))
                    error('Whole brain image already in the database!');
                end
                %continue build insert struct if not
                key.slide_num = slide_n;
                key.brain_num = brain_n;

                %calculate the midline linear function
                if ~(any(isnan(mdp1))||any(isnan(mdp2)))
                    key.midline_slope = (mdp1(2)-mdp2(2))/(mdp1(1)-mdp2(1));
                    key.midline_intercept = mdp1(2)-(key.midline_slope*mdp1(1));
                end

                %try insert
                C = dj.conn;
                C.startTransaction;
                insert(sln_image.WholeBrainImage, key);
                C.commitTransaction;

                fprintf('Inserting success!\n');
                disp(key);


                %return the inserted ref_id
                ids = fetchn(sln_image.WholeBrainImage, 'ref_image_id');
                ref_image_id = max(ids);
                %Warning: usually this safe to do, unless there are more than 1
                %process insert this database at the same time

            catch ME
                if (exist('C', 'var'))
                    C.cancelTransaction;
                end              
                rethrow(ME)

            end
        end


        % function new_ref_id = update_midline(ref_id, mdp1, mdp2)
        %     get_id = append('ref_image_id = ', int2str(ref_id));
        %     data = fetch(sln_image.WholeBrainImage & get_id, '*');
        %     data.midline_slope = (mdp1(2)-mdp2(2))/(mdp1(1)-mdp2(1));
        %     data.midline_intercept = mdp1(2)-(key.midline_slope*mdp1(1));
        %     data = rmfield(data, 'ref_image_id');
        %     try
        %         C = dj.conn;
        %         C.startTransaction;
        %         del(sln_image & get_id);
        %         insert(sln_image.WholeBrainImage, data);
        %         C.commitTransaction;
        %         ids = fetchn(sln_image.WholeBrainImage, 'ref_image_id');
        %         new_ref_id = max(ids);
        %     catch ME
        %         rethrow(ME);
        %     end
        % end
    end
end