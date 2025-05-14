%{
# annotate the whole retina image
->sln_image.Image
-----
->sln_tissue.Retina
cut_orientation: enum('Dorsal', 'Ventral', 'Nasal', 'Temporal')
%}


classdef WholeRetinaImage < dj.Manual
end