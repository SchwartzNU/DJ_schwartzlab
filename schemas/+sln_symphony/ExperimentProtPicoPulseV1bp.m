%{
#b parameters for PicoPulse (1) 
-> sln_symphony.ExperimentEpochBlock
---
number_of_epochs : smallint unsigned
pre_time : float
stim_time : float
tail_time : float
%}
classdef ExperimentProtPicoPulseV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
