function R = behaviorSessionAnalysis(trackingData, pipeline, P)

%analysis parameters
pause_speed_thres = P.pause_speed_thres; %speed threshold to consider a pause
pause_duration_thres = P.pause_duration_thres; %threshold number of seconds to stay paused


inches_per_pixel = 0.022031; %TODO, load from calibration
frameRate = 15; %Hz, TODO, load from calibration

trackingData_struct = fetch(trackingData,'*');

speed_inches_per_s = trackingData_struct.body_speed*inches_per_pixel*frameRate;
R.meanSpeed = mean(speed_inches_per_s);

[~, pause_frames, pause_widths] = findpeaks(-speed_inches_per_s,'MinPeakHeight', -pause_speed_thres, 'MinPeakWidth', pause_duration_thres*frameRate);






% in BehaviorSessionTrackingData
% time_axis : longblob            # vector with units of seconds 
% dlc_raw : longblob              # struct with dlc positions and confidence data
% head_position_arc : longblob    # vector, units of radians
% body_speed : longblob           # vector 1 element shorter than time_axis, units of pixels per frane
% window_visibility : longblob    # logical vector Nframes x 3 columns marking times the animal is visible to windows A,B,C
% gaze_bino_outer : longblob      # vector of estimated binocular gaze positions along the outer wall (radians)
% cumulative_gaze_bino: longblob  # vector Nframes-1 * 3 of the number of frames gazing at each window
% gaze_left_outer : longblob      # vector of estimated left eye gaze positions along the outer wall (radians) assumes 32 degree eye angle
% cumulative_gaze_left: longblob  # vector Nframes-1 * 3 of the number of frames spent gazing of each window, left eye
% gaze_right_outer : longblob     # vector of estimated right eye gaze positions along the outer wall (radians)
% cumulative_gaze_right: longblob # vector Nframes-1 * 3 of the number of frames spent gazing of each window, right eye
% cumulative_body: longblob       # vector Nframes-1 * 3 of the number of frames body center is in front of each window