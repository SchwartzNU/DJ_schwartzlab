%{
# A symphony recording channel
-> sln_symphony.SymphonyEpochBlock
-> sln_symphony.Channel

%}
classdef SymphonyChannel < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end

%cells should associate here?