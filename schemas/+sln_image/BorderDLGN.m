%{
#tabble to store the annotated border of dLGN for each dLGN axon images
->sln_image.Image
---
dlgn_loop: blob@raw #a closed loops of coordinates of dLGN
lateral_idx = NULL:blob@raw #rows that label the lateral side of dLGN
medial_idx= NULL:blob@raw #rows that label the medial side of dLGN
dm_pole_idx:tinyint unsigned #which point is the dorsal medial pole of dLGN
dm_line=NULL: blob@raw #line that contains the dorsal medial pole
vl_pole_idx= NULL: tinyint unsigned #which point is the ventral lateral pole of dLGN
vl_line=NULL:blob@raw #line that contains the ventral medial pole
%}
classdef BorderDLGN < dj.Manual
    methods (Static)
        function check_and_insert(data, image_id) %only 1 of dm or vl pole is ok to left blank
            %check the pole
            flag1 = isnan(data.dm_pole_idx);
            flag2 = isnan(data.vl_pole_idx);

            if ~(flag1 || flag2)
                error('At least one of the poles should be labaled!');
            end

            %check the loop
            loopsize = size(data.loop_xy);
            if (numel(loopsize)~=2 || loopsize(2)~=2)
                error('The shape of dlgn loops is not correct!\n');
            end
            
            key = data;
            key = sln_image.Morph_Util.renameStructField(key, 'loop_xy', 'dlgn_loop');
            key = sln_image.Morph_Util.renameStructField(key, 'dm_idx', 'dm_line');
            key = sln_image.Morph_Util.renameStructField(key, 'vl_idx', 'vl_line');
            key = rmfield(key, 'region');
            key.image_id = image_id; 
            insert(sln_image.BorderDLGN, key);
            disp(key);
            fprintf('Inserted succefully!\n');
        end

        function load_dlgn_fromFolder(folder, image_id)
           S = load(fullfile(folder, 'dLGN_annot.mat'));
           %check the image name fit the name in the database
           q = sprintf('image_id =%d', image_id);
           imdj = fetch(sln_image.Image & q, 'image_filename');
           localfile = dir(fullfile(folder, imdj.image_filename));
           if (isempty(localfile))
               warning('No matching local file matches with the same-named file %d in DJ!\n', image_id);
           end
           sln_image.BorderDLGN.check_and_insert(S.result, image_id);
        end
    end
end
