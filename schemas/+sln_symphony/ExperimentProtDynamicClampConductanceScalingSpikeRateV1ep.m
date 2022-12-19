%{
#e parameters for DynamicClampConductanceScalingSpikeRate (1) 
-> sln_symphony.ExperimentEpoch
---
conductance_matrix_row_index : float
protocol_version : float
%}
classdef ExperimentProtDynamicClampConductanceScalingSpikeRateV1ep < sln_symphony.ExperimentProt
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function e_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
