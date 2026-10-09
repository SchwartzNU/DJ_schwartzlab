%{
#e parameters for ColorOpponentCheckerboard (2) 
-> sln_symphony.ExperimentEpoch
---
protocol_version : float
%}
% Staged by Symphony3\s3_djtables.m: no existing version accepted the file.
% Newest version mismatch: V1: block extra [antialias] missing []; epoch extra [] missing []
classdef ExperimentProtColorOpponentCheckerboardV2ep < sln_symphony.ExperimentProtocol
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
