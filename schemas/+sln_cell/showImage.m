function [] = showImage(cell_identifier,morph_only)
if nargin < 2
    morph_only = true;
end
sln_image.CellImageViewer(num2str(cell_identifier),morph_only);