%{
# Gaze data for a social behavior session (computed from top camera)

-> sl_behavior.TrackingData2D
---
bino_gaze_outer_wall : longblob #vector of gaze angle in radians
bino_gaze_inner_wall : longblob #vector of gaze angle in radians           
%}

classdef GazeData2D < dj.Imported
     methods(Access=protected)
        function makeTuples(self, key)  
            arena_center = [633 510];
            inner_wall_radius = 185;


            tracking_struct = fetch(sl_behavior.TrackingData2D & key, 'n_frames', 'dlc_raw');

            varNames = tracking_struct.dlc_raw.top_parts;
            M = tracking_struct.dlc_raw.top;
            Nvars = length(varNames);

            if tracking_struct.n_frames < 900
                disp('skipping session with fewer than 900 frames');
                return;
            end

            DLC_raw_table_top = table('Size',[size(M,1), Nvars], ...
                'VariableNames', varNames, ...
                'VariableTypes', string(repmat('double',length(varNames), 1)));

            DLC_raw_table_top{:,:} = M;
            theta = zeros(tracking_struct.n_frames, 1);
            rho = zeros(tracking_struct.n_frames, 1);
            
            for i=1:tracking_struct.n_frames
                L_ear = [DLC_raw_table_top.leftear_x(i), DLC_raw_table_top.leftear_y(i)];
                R_ear = [DLC_raw_table_top.rightear_x(i), DLC_raw_table_top.rightear_y(i)];
                head_center = mean([L_ear; R_ear]);
                nose = [DLC_raw_table_top.nose_x(i), DLC_raw_table_top.nose_y(i)];
                head_center_rel = head_center - arena_center;
                nose_rel = nose - arena_center;
                head_nose_vector = nose_rel - head_center_rel;
                [theta(i), rho(i)] = cart2pol(head_nose_vector(1), head_nose_vector(2));
            end
            keyboard;
            
            disp('Insert success');             
            self.insert(key, 'REPLACE');
        end
    end
end