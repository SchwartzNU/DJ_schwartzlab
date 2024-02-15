%{
# Gaze data for a social behavior session (computed from top camera)

-> sl_behavior.TrackingData2D
-> sl_behavior.TopCameraCalibration
---
bino_gaze_outer_wall : longblob #vector of gaze outer wall gaze angle in radians. Nan for frames blocked by inner wall or undefined
inner_wall_gaze : longblob #vector of 1 for frames where mouse is looking at inner wall and 0 for when it is not. NaN for undefined ones          
win_a_gaze_frames : longblob #vector of frames in which animal aims binocular gaze directly at window A
win_b_gaze_frames : longblob #vector of frames in which animal aims binocular gaze directly at window B
win_c_gaze_frames : longblob #vector of frames in which animal aims binocular gaze directly at window C
win_a_gaze_frames_in_bino : longblob #vector of frames in which animal aims central 40 degrees gaze at window A
win_b_gaze_frames_in_bino : longblob #vector of frames in which animal aims central 40 degrees gaze at window B
win_c_gaze_frames_in_bino : longblob #vector of frames in which animal aims central 40 degrees gaze at window C
win_a_gaze_frames_visible : longblob #vector of frames in which animal aims entire 200 degree FOV at window A
win_b_gaze_frames_visible : longblob #vector of frames in which animal aims entire 200 degree FOV at window B
win_c_gaze_frames_visible : longblob #vector of frames in which animal aims entire 200 degree FOV at window C
%}

classdef GazeData2D < dj.Imported
     methods(Access=protected)
        function makeTuples(self, key)  
            calibration = fetch(sl_behavior.TopCameraCalibration & key, '*');    

            arena_center = [calibration.center_x calibration.center_y];            
            inner_wall_radius = calibration.inner_wall_radius;
            outer_wall_radius = 335; 

            scoreThreshold = 0.9; %for DLC tracking from top camera, TODO, read this in from calibration;

            inner_wall = createCircle([0, 0], [0 inner_wall_radius]);
            outer_wall = createCircle([0, 0], [0 outer_wall_radius]);

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

            theta_bino_min = ones(tracking_struct.n_frames, 1) .* nan;
            theta_bino_max = ones(tracking_struct.n_frames, 1) .* nan;        

            rho = ones(tracking_struct.n_frames, 1) .* nan;
            inner_wall_gaze = ones(tracking_struct.n_frames, 1) .* nan;
            
            win_a_gaze_frames_visible = [];
            win_b_gaze_frames_visible = [];
            win_c_gaze_frames_visible = [];
            
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
                    head_nose_ray = createRay(head_center_rel, nose_rel);
                    [ray_angle, ~] = cart2pol(nose_rel(1) - head_center_rel(1), nose_rel(2) - head_center_rel(2));
                    ray_min_angle = ray_angle - deg2rad(20);
                    ray_max_angle = ray_angle + deg2rad(20);
                    bino_min_ray = createRay(head_center_rel, ray_min_angle);
                    bino_max_ray = createRay(head_center_rel, ray_max_angle);
                    ray_min_angle_full = normalizeAngle(ray_angle - deg2rad(110), 0);
                    ray_max_angle_full = normalizeAngle(ray_angle + deg2rad(110), 0);
                    full_min_ray = createRay(head_center_rel, ray_min_angle_full);
                    full_max_ray = createRay(head_center_rel, ray_max_angle_full);

                    inner_wall_intersections = intersectLineCircle(head_nose_ray, inner_wall);  
                    inner_wall_intersections_min = intersectLineCircle(bino_min_ray, inner_wall);
                    inner_wall_intersections_max = intersectLineCircle(bino_max_ray, inner_wall);
                    inner_wall_intersections_min_full = intersectLineCircle(full_min_ray, inner_wall);
                    inner_wall_intersections_max_full = intersectLineCircle(full_max_ray, inner_wall);

                    if isnan(inner_wall_intersections(1,1)) %gaze center not blocked by inner wall                        
                        inner_wall_gaze(i) = 0;
                        outer_wall_intersections = intersectLineCircle(head_nose_ray, outer_wall);
                        nose_dist = pdist2(outer_wall_intersections,nose_rel);
                        head_dist = pdist2(outer_wall_intersections,head_center_rel);
                        dist_diff = nose_dist - head_dist;
                        [~, ind] = min(dist_diff);
                        rho(i) = pdist2(nose_rel,head_center_rel);
                        [theta(i), ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));
                    else
                        theta(i) = nan;
                        inner_wall_gaze(i) = 1;
                    end

                    
                    if isnan(inner_wall_intersections_min_full(1,1)) ||  isnan(inner_wall_intersections_max_full(1,1)) %full 220 degree bino gaze not blocked by inner wall (only possible if mouse is inside chamber I think)
                        for a=1:219
                            test_ray_angle = ray_min_angle_full + deg2rad(a);
                            test_ray = createRay(head_center_rel, test_ray_angle);
                            inner_wall_test_intersections = intersectLineCircle(test_ray, inner_wall);
                            if isnan(inner_wall_test_intersections)
                                outer_wall_intersections = intersectLineCircle(test_ray, outer_wall);
                                nose_dist = pdist2(outer_wall_intersections,nose_rel);
                                head_dist = pdist2(outer_wall_intersections,head_center_rel);
                                dist_diff = nose_dist - head_dist;
                                [~, ind] = min(dist_diff);
                                [theta_test, ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));
                                if theta_test >= calibration.window_a_start_ang && theta_test <= calibration.window_a_end_ang
                                    win_a_gaze_frames_visible = [win_a_gaze_frames_visible, i];
                                elseif theta_test >= calibration.window_b_start_ang && theta_test <= calibration.window_b_end_ang
                                    win_b_gaze_frames_visible = [win_b_gaze_frames_visible, i];
                                elseif theta_test >= calibration.window_c_start_ang && theta_test <= calibration.window_c_end_ang
                                    win_c_gaze_frames_visible = [win_c_gaze_frames_visible, i];
                                end
                            end
                        end
                        

                    end

                    if isnan(inner_wall_intersections_min(1,1)) ||  isnan(inner_wall_intersections_max(1,1)) %full 40 degree bino gaze not blocked by inner wall
                        if isnan(inner_wall_intersections_min(1,1)) &&  isnan(inner_wall_intersections_max(1,1)) %full FOV not blocked
                            %min ray
                            outer_wall_intersections = intersectLineCircle(bino_min_ray, outer_wall);
                            nose_dist = pdist2(outer_wall_intersections,nose_rel);
                            head_dist = pdist2(outer_wall_intersections,head_center_rel);
                            dist_diff = nose_dist - head_dist;
                            [~, ind] = min(dist_diff);
                            [theta_bino_min(i), ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));
                            
                            %max ray
                            outer_wall_intersections = intersectLineCircle(bino_max_ray, outer_wall);
                            nose_dist = pdist2(outer_wall_intersections,nose_rel);
                            head_dist = pdist2(outer_wall_intersections,head_center_rel);
                            dist_diff = nose_dist - head_dist;
                            [~, ind] = min(dist_diff);
                            [theta_bino_max(i), ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));
                                       

                        elseif isnan(inner_wall_intersections_min(1,1)) && ~isnan(inner_wall_intersections_max(1,1)) % max side blocked
                            %min ray
                            outer_wall_intersections = intersectLineCircle(bino_min_ray, outer_wall);
                            nose_dist = pdist2(outer_wall_intersections,nose_rel);
                            head_dist = pdist2(outer_wall_intersections,head_center_rel);
                            dist_diff = nose_dist - head_dist;
                            [~, ind] = min(dist_diff);
                            [theta_bino_min(i), ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));

                            for a=1:39
                                test_ray_angle = ray_max_angle - deg2rad(a);
                                test_ray = createRay(head_center_rel, test_ray_angle);
                                inner_wall_test_intersections = intersectLineCircle(test_ray, inner_wall);  
                                if isnan(inner_wall_test_intersections)
                                    %max ray
                                    outer_wall_intersections = intersectLineCircle(test_ray, outer_wall);
                                    nose_dist = pdist2(outer_wall_intersections,nose_rel);
                                    head_dist = pdist2(outer_wall_intersections,head_center_rel);
                                    dist_diff = nose_dist - head_dist;
                                    [~, ind] = min(dist_diff);
                                    [theta_bino_max(i), ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));
                                    break;
                                end
                            end


                        elseif ~isnan(inner_wall_intersections_min(1,1)) && isnan(inner_wall_intersections_max(1,1)) % min side blocked
                            %max ray
                            outer_wall_intersections = intersectLineCircle(bino_max_ray, outer_wall);
                            nose_dist = pdist2(outer_wall_intersections,nose_rel);
                            head_dist = pdist2(outer_wall_intersections,head_center_rel);
                            dist_diff = nose_dist - head_dist;
                            [~, ind] = min(dist_diff);
                            [theta_bino_max(i), ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));

                            for a=1:39
                                test_ray_angle = ray_min_angle + deg2rad(a);
                                test_ray = createRay(head_center_rel, test_ray_angle);
                                inner_wall_test_intersections = intersectLineCircle(test_ray, inner_wall);  
                                if isnan(inner_wall_test_intersections)
                                    %min ray
                                    outer_wall_intersections = intersectLineCircle(test_ray, outer_wall);
                                    nose_dist = pdist2(outer_wall_intersections,nose_rel);
                                    head_dist = pdist2(outer_wall_intersections,head_center_rel);
                                    dist_diff = nose_dist - head_dist;
                                    [~, ind] = min(dist_diff);
                                    [theta_bino_min(i), ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));
                                    break;
                                end
                            end

                        end                                               
                        nose_dist = pdist2(outer_wall_intersections,nose_rel);
                        head_dist = pdist2(outer_wall_intersections,head_center_rel);
                        dist_diff = nose_dist - head_dist;
                        [~, ind] = min(dist_diff);
                        rho(i) = pdist2(nose_rel,head_center_rel);
                        [theta(i), ~] = cart2pol(outer_wall_intersections(ind,1),outer_wall_intersections(ind,2));
                    else
                        theta(i) = nan;
                        inner_wall_gaze(i) = 1;
                    end


                end
            end
            theta = normalizeAngle(theta, 0);
            theta_bino_min = normalizeAngle(theta_bino_min, 0);
            theta_bino_max = normalizeAngle(theta_bino_max, 0);

            %remove error points where vector length is beyond 2 stds from
            %the mean and interpolate them if possible
            ind = find(rho > nanmean(rho) + 3 * nanstd(rho) | rho < nanmean(rho) - 3 * nanstd(rho));            
            theta(ind) = nan;
            inner_wall_gaze(ind) = nan;
            theta_bino_min(ind) = nan;
            theta_bino_max(ind) = nan;

            fprintf('%d of %d frames (%f percent) interpolated due to bad coordinates. \n', ...
                length(ind), tracking_struct.n_frames, 100*length(ind)./tracking_struct.n_frames);
            
            good_ind = setdiff(1:tracking_struct.n_frames, ind);
            theta_for_interp = theta(good_ind);
            theta_bino_min_for_interp = theta_bino_min(good_ind);       
            theta_bino_max_for_interp = theta_bino_max(good_ind);    

            inner_wall_gaze_for_interp = inner_wall_gaze(good_ind);
            x = 1:tracking_struct.n_frames;
            x_for_interp = x(good_ind);

            theta(ind) = interp1(x_for_interp,theta_for_interp,ind);
            theta_bino_min(ind) = interp1(x_for_interp,theta_bino_min_for_interp,ind);
            theta_bino_max(ind) = interp1(x_for_interp,theta_bino_max_for_interp,ind);

            inner_wall_gaze(ind) = round(interp1(x_for_interp,inner_wall_gaze_for_interp,ind));

            fprintf('%d of %d frames (%f percent) spent looking at inner wall. \n', ...
                nansum(inner_wall_gaze), tracking_struct.n_frames, 100*nansum(inner_wall_gaze)./tracking_struct.n_frames);            
                
            key.bino_gaze_outer_wall = theta;
            key.inner_wall_gaze = inner_wall_gaze;

            key.win_a_gaze_frames_visible = unique(win_a_gaze_frames_visible);
            key.win_b_gaze_frames_visible = unique(win_b_gaze_frames_visible);
            key.win_c_gaze_frames_visible = unique(win_c_gaze_frames_visible);            

            key.win_a_gaze_frames_in_bino = [];
            key.win_b_gaze_frames_in_bino = [];
            key.win_c_gaze_frames_in_bino = [];
            for f=1:length(theta_bino_min)
                if ~isnan(theta_bino_min(f)) && ~isnan(theta_bino_max(f))
                    if (theta_bino_min(f) > calibration.window_a_start_ang && theta_bino_min(f) <= calibration.window_a_end_ang) || ...
                        (theta_bino_max(f) > calibration.window_a_start_ang && theta_bino_min(f) <= calibration.window_a_end_ang) 
                        key.win_a_gaze_frames_in_bino = [key.win_a_gaze_frames_in_bino, f];
                    end
                    if (theta_bino_min(f) > calibration.window_b_start_ang && theta_bino_min(f) <= calibration.window_b_end_ang) || ...
                        (theta_bino_max(f) > calibration.window_b_start_ang && theta_bino_min(f) <= calibration.window_b_end_ang) 
                        key.win_b_gaze_frames_in_bino = [key.win_b_gaze_frames_in_bino, f];
                    end
                    if (theta_bino_min(f) > calibration.window_c_start_ang && theta_bino_min(f) <= calibration.window_c_end_ang) || ...
                        (theta_bino_max(f) > calibration.window_c_start_ang && theta_bino_min(f) <= calibration.window_c_end_ang) 
                        key.win_c_gaze_frames_in_bino = [key.win_c_gaze_frames_in_bino, f];
                    end
                end
            end

            key.win_a_gaze_frames = find(theta >= calibration.window_a_start_ang & theta <= calibration.window_a_end_ang);
            key.win_b_gaze_frames = find(theta >= calibration.window_b_start_ang & theta <= calibration.window_b_end_ang);
            key.win_c_gaze_frames = find(theta >= calibration.window_c_start_ang & theta <= calibration.window_c_end_ang);

            if isempty(key.win_a_gaze_frames), key.win_a_gaze_frames = 0; end %can't be NULL
            if isempty(key.win_b_gaze_frames), key.win_b_gaze_frames = 0; end %can't be NULL
            if isempty(key.win_c_gaze_frames), key.win_c_gaze_frames = 0; end %can't be NULL
            if isempty(key.win_a_gaze_frames_in_bino), key.win_a_gaze_frames = 0; end %can't be NULL
            if isempty(key.win_b_gaze_frames_in_bino), key.win_b_gaze_frames = 0; end %can't be NULL
            if isempty(key.win_c_gaze_frames_in_bino), key.win_c_gaze_frames = 0; end %can't be NULL
            
            disp('Insert success');             
            self.insert(key, 'REPLACE');
        end
    end
end