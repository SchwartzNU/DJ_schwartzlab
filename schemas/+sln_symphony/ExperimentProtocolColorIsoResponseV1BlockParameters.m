%{
#Block parameters for ColorIsoResponse (1) 
-> sln_symphony.ExperimentEpochBlock
---
stimulus_mode : enum('Center','Surround','Center-Surround)
inner_diameter : float
outer_diameter : float
pre_time : floats
rstar_mean : float
spot_diameter : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtocolColorIsoResponseV1BlockParameters < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'session_id'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
