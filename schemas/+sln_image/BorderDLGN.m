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
            flag1 = isnan(data.dm_pole_idx);
            flag2 = isnan(data.vl_pole_idx);

            if ~(flag1 || flag2)
                error('At least one of the poles should be labaled!');
            end
            key = data;
            key.image_id = image_id;          
            insert(key, sln_image.BorderDLGN);

        end


    end
end
