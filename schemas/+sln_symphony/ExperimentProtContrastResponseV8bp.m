%{
#Block parameters for ContrastResponse (8) 
-> sln_symphony.ExperimentEpochBlock
---
contrast_direction : enum('negative','positive','both')
max_contrast : float
mean_level : float
min_contrast : float
number_of_contrast_steps : smallint unsigned
number_of_cycles : smallint unsigned
pre_time : float
real_number_of_contrast_steps : smallint unsigned
spot_diameter : float
stim_time : float
tail_time : float
rstar_mean = NULL : float
shape: enum('ellipse', 'rectangle')
uniform_xy : enum('F', 'T')
antialias : enum('F', 'T')
%}
classdef ExperimentProtContrastResponseV8bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct();

		%attributes to be removed from the key
		dropped_attributes = {'red_led'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		t = {block_key(:).antialias};
            i = cellfun(@logical, t);
            [t{i}] = deal('T');
            [t{~i}] = deal('F');
            [block_key(:).antialias]  = t{:};
        t_2 = {block_key(:).uniform_xy};
            i = cellfun(@logical, t_2);
            [t_2{i}] = deal('T');
            [t_2{~i}] = deal('F');
            [block_key(:).uniform_xy]  = t_2{:};
        
		end
	end
end
