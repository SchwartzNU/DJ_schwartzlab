%{
#annotate the whole brain images stored as sln_image.Image
->sln_image.WholeBrainImage
-----
midline_x1:double 
midline_y1:double
midline_x2:double
midline_y2:double
%}


classdef WholeBrainMidline < dj.Manual
    methods(Static)
        function ml = calculate_distance_to_midline(poi, wholeBrain_id)
                q.ref_image_id = wholeBrain_id;
                wholebrain = fetch(sln_image.WholeBrainMidline &q, '*' );
                p1 = [wholebrain.midline_x1, wholebrain.midline_y1];
                p2 = [wholebrain.midline_x2, wholebrain.midline_y2];
                poi = poi(:);
                p1 = p1(:);
                p2 = p2(:);

                v= p2-p1;
                w = poi-p1;

                ml = abs(det([v, w]))/norm(v);

        end
    end
end