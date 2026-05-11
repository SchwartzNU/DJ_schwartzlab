%{
#Notations of dLGN in a coronal brain slice, used in combination of axon image in dLGN 
->sln_image.WholeBrainImage
---
annotationSide: enum('Contralateral', 'Ipsilateral', 'Both')
[nullable]cvm_x:double #x coordinate of the dorsal medial point, contralateral
[nullable]cvm_y: double #same, but y, contralateral
[nullable]cvl_x:double #x coordinate of the dorsal lateral point, contralateral
[nullable]cvl_y: double #y coodinate, contralateral
[nullable]cd_x:double #the most ventral point, contralateral
[nullable]cd_y:double 
[nullable]ivm_x:double #x coordinate of the dorsal medial point, ipsilateral
[nullable]ivm_y: double
[nullable]ivl_x:double 
[nullable]ivl_y: double 
[nullable]id_x:double 
[nullable]id_y:double
%}
classdef Annot_dLGN < dj.Manual
    methods (Static)
        function insert_annotation(ref_id, side, coord_mtrx) %coord_mtrx should be either 3x2 or 6x2, depending on how many sides are being annotated
            q = sprintf('ref_image__id = %d', ref_id);
            check = fetch(sln_image.Annot_dLGN & q);
            if (~isempty(check))
                fprintf('Annotation already exist %d !, skipping...\n', ref_id);
                return
            end

            %check if side is in the set enum
            validSides = {'Contralateral', 'Ipsilateral', 'Both'};
            idx = find(strcmp(side, validSides));
            if (isempty(idx))
                error('Invalid side specified. Must be one of: Contralateral, Ipsilateral, Both.');
            end

            %input key according to the annotation side
            key= [];
            key.annotationSide = side;
            key.ref_image_id = ref_id;
            if (idx == 1) %contra
                key.cvm_x = coord_mtrx(1, 1);
                key.cvm_y = coord_mtrx(1, 2);
                key.cvl_x = coord_mtrx(2, 1);
                key.cvl_y = coord_mtrx(2, 2);
                key.cd_x = coord_mtrx(3, 1);
                key.cd_y = coord_mtrx(3, 2);
            elseif(idx ==2) %ipsilateral
                key.ivm_x = coord_mtrx(1, 1);
                key.ivm_y = coord_mtrx(1, 2);
                key.ivl_x = coord_mtrx(2, 1);
                key.ivl_y = coord_mtrx(2, 2);
                key.id_x = coord_mtrx(3, 1);
                key.id_y = coord_mtrx(3, 2);
            else %both sides are getting annotated, rare but could happen
                key.cvm_x = coord_mtrx(1, 1);
                key.cvm_y = coord_mtrx(1, 2);
                key.cvl_x = coord_mtrx(2, 1);
                key.cvl_y = coord_mtrx(2, 2);
                key.cd_x = coord_mtrx(3, 1);
                key.cd_y = coord_mtrx(3, 2);
                key.ivm_x = coord_mtrx(4, 1);
                key.ivm_y = coord_mtrx(4, 2);
                key.ivl_x = coord_mtrx(5, 1);
                key.ivl_y = coord_mtrx(5, 2);
                key.id_x = coord_mtrx(6, 1);
                key.id_y = coord_mtrx(6, 2);
            end
            %try insert
            try
                   C = dj.conn;
                C.startTransaction;
                insert(sln_image.Annot_dLGN, key);
                C.commitTransaction;
                fprintf('Successfully inserted: \n');
                disp(key);
            catch ME
                rethrow (ME);
            end

        end
    end
end