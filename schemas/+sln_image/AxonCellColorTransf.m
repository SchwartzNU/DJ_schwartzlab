%{
#table that store the affine transformation from cell color coding to axon
->sln_animal.Animal
--- 
cell_encoding:blob
axon_list:blob # list of axon id
axon_encoding:blob
cell_by_match: blob # list of cell_unid 
A: blob #affine parameter
b: blob #affine parameter
%}

classdef AxonCellColorTransf < dj.Manual
end