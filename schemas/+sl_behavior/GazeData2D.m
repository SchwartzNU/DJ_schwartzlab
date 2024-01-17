%{
# Gaze data for a social behavior session (computed from top camera)

-> sl_behavior.TrackingData2D
-> sl_behavior.TopCameraCalibration
---
bino_gaze_outer_wall : longblob #vector of gaze outer wall gaze angle in radians. Nan for frames blocked by inner wall or undefined
inner_wall_gaze : longblob #vector of 1 for frames where mouse is looking at inner wall and 0 for when it is not. NaN for undefined ones          
win_a_gaze_frames : longblob #vector of frames in which animal aims binocular gaze at window A
win_b_gaze_frames : longblob #vector of frames in which animal aims binocular gaze at window B
win_c_gaze_frames : longblob #vector of frames in which animal aims binocular gaze at window C
%}

classdef GazeData2D < dj.Imported
     methods(Access=protected)
        function makeTuples(self, key)  
            calibration = fetch(sl_behavior.TopCameraCalibration & key, '*');    

            arena_center = [calibration.center_x calibration.center_y];            
            inner_wall_radius = calibration.inner_wall_radius;
            scoreThreshold = 0.9; %for DLC tracking from top camera, TODO, read this in from calibration;

            inner_wall = createCircle([0, 0], [0 inner_wall_radius]);

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
            theta = ones(tracking_struct.n_frames, 1) .* nan;
            rho = ones(tracking_struct.n_frames, 1) .* nan;
            inner_wall_gaze = ones(tracking_struct.n_frames, 1) .* nan;
            
            for i=1:tracking_struct.n_frames
                if DLC_raw_table_top.leftear_likelihood(i) < scoreThreshold || ...
                        DLC_raw_table_top.rightear_likelihood(i) < scoreThreshold || ...
                        DLC_raw_table_top.nose_likelihood(i) < scoreThreshold
                    %do nothing, leave nans
                else
                    L_ear = [DLC_raw_table_top.leftear_x(i), DLC_raw_table_top.leftear_y(i)];
                    R_ear = [DLC_raw_table_top.rightear_x(i), DLC_raw_table_top.rightear_y(i)];
                    head_center = mean([L_ear; R_ear]);
                    nose = [DLC_raw_table_top.nose_x(i), DLC_raw_table_top.nose_y(i)];
                    head_center_rel = head_center - arena_center;
                    nose_rel = nose - arena_center;
                    head_nose_vector = nose_rel - head_center_rel;
                    [theta(i), rho(i)] = cart2pol(head_nose_vector(1), head_nose_vector(2));
                    head_nose_ray = createRay(head_center_rel, theta(i));
                    inner_wall_intersections = intersectLineCircle(head_nose_ray, inner_wall);
                    if isnan(inner_wall_intersections(1,1)) %not blocked by inner wall                        
                        inner_wall_gaze(i) = 0;
                    else
                        theta(i) = nan;
                        inner_wall_gaze(i) = 1;
                    end
                end
            end

            %remove error points where vector length is beyond 2 stds from
            %the mean and interpolate them if possible
            ind = find(rho > nanmean(rho) + 2 * nanstd(rho) | rho < nanmean(rho) - 2 * nanstd(rho));
            theta(ind) = nan;
            inner_wall_gaze(ind) = nan;

            fprintf('%d of %d frames (%f percent) interpolated due to bad coordinates. \n', ...
                length(ind), tracking_struct.n_frames, 100*length(ind)./tracking_struct.n_frames);
            
            good_ind = setdiff(1:tracking_struct.n_frames, ind);
            theta_for_interp = theta(good_ind);       
            inner_wall_gaze_for_interp = inner_wall_gaze(good_ind);
            x = 1:tracking_struct.n_frames;
            x_for_interp = x(good_ind);

            for i=1:length(ind)
                theta(ind(i)) = interp1(x_for_interp,theta_for_interp,ind(i));
                inner_wall_gaze(ind(i)) = round(interp1(x_for_interp,inner_wall_gaze_for_interp,ind(i)));
            end

            fprintf('%d of %d frames (%f percent) spent looking at inner wall. \n', ...
                nansum(inner_wall_gaze), tracking_struct.n_frames, 100*nansum(inner_wall_gaze)./tracking_struct.n_frames);            
                
            key.bino_gaze_outer_wall = theta;
            key.inner_wall_gaze = inner_wall_gaze;

            key.win_a_gaze_frames = find(theta >= calibration.window_a_start_ang & theta < calibration.window_a_end_ang);
            key.win_b_gaze_frames = find(theta >= calibration.window_b_start_ang & theta < calibration.window_b_end_ang);
            key.win_c_gaze_frames = find(theta >= calibration.window_c_start_ang & theta < calibration.window_c_end_ang);

            disp('Insert success');             
            self.insert(key, 'REPLACE');
        end
    end
end