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
    methods
        function [slope, intercept] = calculate_line(self)
        end
    end
    methods(Static)
        function upload_from_qupath_annotation(annot_file)
        end
    end
end