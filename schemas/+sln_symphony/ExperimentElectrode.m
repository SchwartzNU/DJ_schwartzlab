%{
# A symphony electrode channel for a block of epochs
-> sln_symphony.ExperimentChannel
---
 (cell_id) -> sln_symphony.ExperimentCell
recording_mode              : enum('Voltage clamp','Current clamp') # units for this recording
hold                        : float                         # the hold signal in pA or mV
amp_mode                    : enum('Cell attached','Whole cell','PerforatedEscin','PerforatedAmpho','PerforatedGrami') # 
%}
classdef ExperimentElectrode < sln_symphony.ExperimentPart
    properties(SetAccess=protected)
        master = sln_symphony.Experiment;
    end
end
