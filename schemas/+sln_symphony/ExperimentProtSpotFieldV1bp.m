%{
    #Block parameters for SpotField (1)
    -> sln_symphony.ExperimentEpochBlock
    ---
    spot_size : float
    extent_x : float
    extent_y : float
    arms : smallint unsigned
    spots_per_arm :smallint unsigned
    spot_stim_frames : smallint unsigned
    spot_pre_frames : smallint unsigned
    spot_tail_frames : smallint unsigned
    spot_intensity : float
    grid_mode : enum('grid','random','rings','radial')
    coverage : float
    seed : smallint # -1 and non-neg integers max out at 32767
    number_of_fields : smallint unsigned
    spot_led : smallint unsigned #maybe tinyint
    stim_time: mediumint unsigned
    pre_time: smallint unsigned
    tail_time : smallint unsigned 
    rstar_intensity_spot : float
    sstar_intensity_spot : float
    mstar_intensity_spot : float
    rstar_mean : float
   
    mean_level : float
    antialias : enum('F','T')
%}

classdef ExperimentProtSpotFieldV1bp < sln_symphony.ExperimentProtocol 
properties

        %attributes to be renamed
        renamed_attributes = struct();

        %attributes to be removed from the key
        dropped_attributes = {'theta'};
    end

    methods
        function block_key = add_attributes(self, block_key, epoch_key) %#ok<INUSL,INUSD>
            %add entities to the key based on others
                
                %tobool
                t = {block_key(:).antialias};
                i = cellfun(@logical, t);
                [t{i}] = deal('T');
                [t{~i}] = deal('F');
                [block_key(:).antialias]  = t{:};
            end
    end
end

