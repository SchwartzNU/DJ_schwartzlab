%{
# A symphony electrode channel
-> sln_symphony.SymphonyChannel
---
(cell_id) -> sln_symphony.SymphonyCell(source_id)
recording_mode : enum('Voltage clamp','Current clamp') # units for this recording
hold : float  # the hold signal in pA or mV
amp_mode : enum('Cell attached','Whole cell')
%}
classdef SymphonyElectrode < dj.Part
    properties(SetAccess=protected)
        master = sln_symphony.Symphony;
    end
end