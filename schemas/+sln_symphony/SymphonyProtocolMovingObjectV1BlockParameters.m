%{
#Block parameters for MovingObject (1) 
-> sln_symphony.SymphonyEpochBlock
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
classdef SymphonyProtocolMovingObjectV1BlockParameters < sln_symphony.SymphonyProtocol
	properties

		%attributes to be renamed
		renamed_attributes = struct('set_directions','number_of_directions','set_shapes','object_shape');

		%attributes to be removed from the key
		dropped_attributes = {'diameters','diameter',...
		'directions','offsets','set_diameters','set_offsets',...
		'set_speeds','speeds'};
	end
	methods
		function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
		%add entities to the key based on others
				%min speed, max speed, number of speeds
				min_speed = arrayfun(@(x) x.set_speeds(1), block_key,'uni',0);
				max_speed = arrayfun(@(x) x.set_speeds(2), block_key,'uni',0);
				num_speed = arrayfun(@(x) x.set_speeds(3), block_key,'uni',0);

				%min offset, max offset, number of offsets
				min_offset = arrayfun(@(x) x.set_offsets(1), block_key,'uni',0);
				max_offset = arrayfun(@(x) x.set_offsets(2), block_key,'uni',0);
				num_offset = arrayfun(@(x) x.set_offsets(3), block_key,'uni',0);

				%min diameter, max diameter, number of diameters
				min_diameter = arrayfun(@(x) x.set_diameters(1), block_key,'uni',0);
				max_diameter = arrayfun(@(x) x.set_diameters(2), block_key,'uni',0);
				num_diameter = arrayfun(@(x) x.set_diameters(3), block_key,'uni',0);

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
