%{
# A recording of a cell in a user-defined dataset
-> sln_symphony.DatasetCell
-> sln_symphony.SymphonyEpochChannel
%}
classdef DatasetCellEpochChannel < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Dataset;
    end
end
