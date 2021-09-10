%{
# A channel captured in a user-defined dataset
-> sln_symphony.Dataset
-> sln_cell.Cell # the actual cell this channel represents
%}
classdef DatasetCell < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Dataset;
    end
end
