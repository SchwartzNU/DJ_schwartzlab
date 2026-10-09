%{
#e parameters for RandomMotionEdge (4) 
-> sln_symphony.ExperimentEpoch
---
movement_angle : float
protocol_version : float
%}
% Staged by Symphony3\s3_djtables.m: no existing version accepted the file.
% Newest version mismatch: V3: block extra [antialias] missing []; epoch extra [] missing []
classdef ExperimentProtRandomMotionEdgeV4ep < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {};
	end
	methods
		function epoch_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
		end
	end
end
