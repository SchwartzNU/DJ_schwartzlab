%{
# A symphony electrode channel
-> sln_symphony.ExperimentChannel
---
(cell_id) -> sln_symphony.ExperimentCell(source_id)
recording_mode : enum('Voltage clamp','Current clamp') # units for this recording
hold : float  # the hold signal in pA or mV
amp_mode : enum('Cell attached','Whole cell')
%}
classdef ExperimentElectrode < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Experiment;
    end
end