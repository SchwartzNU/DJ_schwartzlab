%{
#Block parameters for MovingObject (1) 
-> sln_symphony.ExperimentEpochBlock
---
center_time_shift : float
intensity : float
mean_level : float
number_of_cycles : smallint unsigned
pre_time : float
rstar_mean : float
number_of_directions : tinyint unsigned
object_shape : enum('circle','rectangle')
stim_time : float
tail_time : float
min_speed : float
max_speed : float
number_of_speeds : tinyint unsigned
min_offset : float
max_offset : float
number_of_offsets : tinyint unsigned
min_diameter : float
max_diameter : float
number_of_diameters : tinyint unsigned
%}
classdef ExperimentProtMovingObjectV1bp < sln_symphony.ExperimentProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct('set_directions','number_of_directions','set_shapes','object_shape');

		%attributes to be removed from the key
		dropped_attributes = {'diameters','diameter',...
		'directions','offsets','set_diameters','set_offsets',...
		'set_speeds','speeds','antialias'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
				%min speed, max speed, number of speeds
				min_speed = arrayfun(@(x) x.set_speeds(1), block_key,'uni',0);
				max_speed = arrayfun(@(x) x.set_speeds(2), block_key,'uni',0);
                has_num = arrayfun(@(x) numel(x.set_speeds)==3, block_key);
                num_speed = ones(size(min_speed));
                num_speed(has_num) = arrayfun(@(x) x.set_speeds(3), block_key(has_num));
                num_speed = num2cell(num_speed);

				%min offset, max offset, number of offsets
				min_offset = arrayfun(@(x) x.set_offsets(1), block_key,'uni',0);
				max_offset = arrayfun(@(x) x.set_offsets(2), block_key,'uni',0);
				has_num = arrayfun(@(x) numel(x.set_offsets)==3, block_key);
                num_offset = ones(size(min_offset));
                num_offset(has_num) = arrayfun(@(x) x.set_offsets(3), block_key(has_num));
                num_offset = num2cell(num_offset);
                
                
				%min diameter, max diameter, number of diameters
				min_diameter = arrayfun(@(x) x.set_diameters(1), block_key,'uni',0);
				max_diameter = arrayfun(@(x) x.set_diameters(2), block_key,'uni',0);
				has_num = arrayfun(@(x) numel(x.set_diameters)==3, block_key);
                num_diameter = ones(size(min_diameter));
                num_diameter(has_num) = arrayfun(@(x) x.set_diameters(3), block_key(has_num));
                num_diameter = num2cell(num_diameter);

				[block_key(:).min_speed] = min_speed{:};
				[block_key(:).max_speed] = max_speed{:};
				[block_key(:).number_of_speeds] = num_speed{:};

				[block_key(:).min_offset] = min_offset{:};
				[block_key(:).max_offset] = max_offset{:};
				[block_key(:).number_of_offsets] = num_offset{:};

				[block_key(:).min_diameter] = min_diameter{:};
				[block_key(:).max_diameter] = max_diameter{:};
				[block_key(:).number_of_diameters] = num_diameter{:};

		end
	end
end
