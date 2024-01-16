%{
# Nose position data for a social behavior session (computed from top camera)

-> sl_behavior.TrackingData2D
---
nose_position_from_center : longblob #vector nose position relative to arena origin
nose_angle_from_center : longblob #vector nose angle relative to arena origin
in_arena_frame : int unsigned #frame at which mouse enters the arena
%}

classdef NoseData2D < dj.Imported
     methods(Access=protected)
        function makeTuples(self, key)  
            arena_center = [633 510];
            inner_wall_radius = 185;
            scoreThreshold = 0.9; %for DLC tracking from top camera, TODO, read this in from calibration;

            %inner_wall = createCircle([0, 0], [0 inner_wall_radius]);

            tracking_struct = fetch(sl_behavior.TrackingData2D & key, 'n_frames', 'dlc_raw');

            varNames = tracking_struct.dlc_raw.top_parts;
            M = tracking_struct.dlc_raw.top;
            Nvars = length(varNames);

            DLC_raw_table_top = table('Size',[size(M,1), Nvars], ...
                'VariableNames', varNames, ...
                'VariableTypes', string(repmat('double',length(varNames), 1)));

            DLC_raw_table_top{:,:} = M;

            if tracking_struct.n_frames < 900
                disp('skipping session with fewer than 900 frames');
                return;
            end

            theta = ones(tracking_struct.n_frames, 1) .* nan;
            nose_rel_x = ones(tracking_struct.n_frames, 1) .* nan;
            nose_rel_y = ones(tracking_struct.n_frames, 1) .* nan;
            in_arena = zeros(tracking_struct.n_frames, 1);
            
            for i=1:tracking_struct.n_frames
                if  DLC_raw_table_top.nose_likelihood(i) < scoreThreshold
                    %do nothing, leave nans
                else                 
                    nose = [DLC_raw_table_top.nose_x(i), DLC_raw_table_top.nose_y(i)];
                    nose_rel = nose - arena_center;
                    nose_rel_x(i) = nose_rel(1);
                    nose_rel_y(i) = nose_rel(2);
                    
                    [theta(i), rho] = cart2pol(nose_rel_x(i), nose_rel_y(i));
                    if rho > inner_wall_radius
                        in_arena(i) = 1;
                    end
                end
            end

            keyboard;

            disp('Insert success');             
            self.insert(key, 'REPLACE');
        end
    end
end