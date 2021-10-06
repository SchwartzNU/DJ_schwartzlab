%{
# A recording epoch in a user-defined dataset
-> sln_symphony.Dataset
-> sln_symphony.ExperimentEpoch
%}
classdef DatasetEpoch < sln_symphony.ExperimentPart
    properties(SetAccess=protected)
        master = sln_symphony.Dataset;
    end
end
