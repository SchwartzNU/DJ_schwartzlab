%{
# Nose position data for a social behavior session (computed from top camera)

-> sl_behavior.TrackingData2D
-> sl_behavior.TopCameraCalibration
---
nose_position_from_center : longblob #vector nose position relative to arena origin
nose_angle_from_center : longblob #vector nose angle relative to arena origin
closest_window : longblob #window to which nose is closest: 1=A, 2=B, 3=C
angle_from_window : longblob #angle (radians) from closest window
distance_from_window : longblob #pixels from closest window
%}

classdef NoseData2D < dj.Imported
     methods(Access=protected)
        function makeTuples(self, key)  
            calibration = fetch(sl_behavior.TopCameraCalibration & key, '*');    

            arena_center = [calibration.center_x calibration.center_y];       

            win_a = createLine(calibration.window_a_start'-arena_center, calibration.window_a_end'-arena_center);
            win_b = createLine(calibration.window_b_start'-arena_center, calibration.window_b_end'-arena_center);
            win_c = createLine(calibration.window_c_start'-arena_center, calibration.window_c_end'-arena_center);
            
            win_a_center = mean([calibration.window_a_start_ang, calibration.window_a_end_ang]);
            win_b_center = mean([calibration.window_b_start_ang, calibration.window_b_end_ang]);
            win_c_center = mean([calibration.window_c_start_ang, calibration.window_c_end_ang]);

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
            
            for i=1:tracking_struct.n_frames
                if  DLC_raw_table_top.nose_likelihood(i) < scoreThreshold
                    %do nothing, leave nans
                else                 
                    nose = [DLC_raw_table_top.nose_x(i), DLC_raw_table_top.nose_y(i)];
                    nose_rel = nose - arena_center;
                    nose_rel_x(i) = nose_rel(1);
                    nose_rel_y(i) = nose_rel(2);
                    
                    [theta(i), rho] = cart2pol(nose_rel_x(i), nose_rel_y(i));
                end
            end
            
            good_ind = ~isnan(theta);
            nan_ind = find(isnan(theta));
            theta_for_interp = theta(good_ind);
            nose_x_for_interp = nose_rel_x(good_ind);
            nose_y_for_interp = nose_rel_y(good_ind);

            x = 1:tracking_struct.n_frames;
            x_for_interp = x(good_ind);
            theta(nan_ind) = interp1(x_for_interp,theta_for_interp, nan_ind);
            nose_rel_x(nan_ind) = interp1(x_for_interp,nose_x_for_interp, nan_ind);
            nose_rel_y(nan_ind) = interp1(x_for_interp,nose_y_for_interp, nan_ind);

            fprintf('%d of %d frames (%f percent) interpolated due to bad coordinates. \n', ...
                length(nan_ind), tracking_struct.n_frames, 100*length(nan_ind)./tracking_struct.n_frames);

            key.nose_position_from_center = [nose_rel_x, nose_rel_y];
            key.nose_angle_from_center = theta;     

            angle_from_a = abs(angleDiff(theta,win_a_center));
            angle_from_b = abs(angleDiff(theta,win_b_center));
            angle_from_c = abs(angleDiff(theta,win_c_center));
            
            key.closest_window = zeros(tracking_struct.n_frames, 1);
            key.angle_from_window = zeros(tracking_struct.n_frames, 1);
            key.distance_from_window = zeros(tracking_struct.n_frames, 1);
            for i=1:tracking_struct.n_frames
                [key.angle_from_window(i), key.closest_window(i)] = min([angle_from_a(i), angle_from_b(i), angle_from_c(i)]);                
                switch(key.closest_window(i))
                    case 1
                        key.distance_from_window(i) = distancePointLine([nose_rel_x(i), nose_rel_y(i)], win_a);
                    case 2
                        key.distance_from_window(i) = distancePointLine([nose_rel_x(i), nose_rel_y(i)], win_b);
                    case 3
                        key.distance_from_window(i) = distancePointLine([nose_rel_x(i), nose_rel_y(i)], win_c);
                end
            end

            disp('Insert success');             
            self.insert(key, 'REPLACE');
        end
    end
end