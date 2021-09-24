%{
# A symphony recording channel for a single epoch
-> sln_symphony.SymphonyEpoch
-> sln_symphony.SymphonyChannel
---
raw_data : blob@raw #the actual raw data for this epoch

%}
classdef SymphonyEpochChannel < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end
