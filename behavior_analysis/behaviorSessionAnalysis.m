function R = behaviorSessionAnalysis(trackingData, pipeline, P)

%analysis parameters
pause_speed_thres = P.pause_speed_thres; %speed threshold to consider a pause
pause_duration_thres = P.pause_duration_thres; %threshold number of seconds to stay paused
analysis_end = P.analysis_end; %time in seconds after mouse exist chamber to stop analysis
nose_contact_thres = P.nose_contact_thres; %threshold (inches) for counting a nose contact
nose_contact_duration_thres = P.nose_contact_duration_thres; %threshold (seconds) for counting a nose contact
window_order = P.window_order; %3 element vector specifying how to order the windows

inches_per_pixel = 0.022031; %TODO, load from calibration
frameRate = 15; %Hz, TODO, load from calibration

trackingData_struct = fetch(trackingData,'*');

speed_inches_per_s = trackingData_struct.body_speed*inches_per_pixel*frameRate;

[~, pause_frames, pause_widths] = findpeaks(-speed_inches_per_s,'MinPeakHeight', -pause_speed_thres, 'MinPeakWidth', pause_duration_thres*frameRate);

trialStart = find(~isnan(trackingData_struct.head_position_arc),1);
trialEnd = trialStart + round(analysis_end*frameRate);

[~, contact_frames_A, contact_widths_A] = findpeaks(-trackingData_struct.nose_window_dist(:,1),'MinPeakHeight', -nose_contact_thres, 'MinPeakWidth', nose_contact_duration_thres*frameRate);

% plot(trackingData_struct.time_axis, trackingData_struct.nose_window_dist(:,1));
% pause;

[~, contact_frames_B, contact_widths_B] = findpeaks(-trackingData_struct.nose_window_dist(:,2),'MinPeakHeight', -nose_contact_thres, 'MinPeakWidth', nose_contact_duration_thres*frameRate);
[~, contact_frames_C, contact_widths_C] = findpeaks(-trackingData_struct.nose_window_dist(:,3),'MinPeakHeight', -nose_contact_thres, 'MinPeakWidth', nose_contact_duration_thres*frameRate);

Nframes = length(trackingData_struct.head_position_arc);
if trialEnd > Nframes
    disp(['Warning: ' num2str(analysis_end) ' after mouse exits chamber is past end of recording.']);
    trialEnd = Nframes-1;
    analysis_end = (trialEnd - trialStart) / frameRate;
end

R.meanSpeed = nanmean(speed_inches_per_s(trialStart:trialEnd));
    
ind = pause_frames > trialStart + frameRate; %1 sec after mouse comes out start looking for pauses
R.pause_frames = pause_frames(ind);
R.pause_head_positions = trackingData_struct.head_position_arc(R.pause_frames);
R.pause_widths = pause_widths(ind) / frameRate;

R.Npauses = length(R.pause_frames);
if R.pause_frames
    R.first_pause_time = double(trackingData_struct.time_axis(R.pause_frames(1)-trialStart)); %seconds
else
    R.first_pause_time = nan;
end

%fix this in importer
%trackingData_struct.cumulative_gaze_bino = trackingData_struct.cumulative_gaze_bino';

R.gaze_bino_s = double(trackingData_struct.cumulative_gaze_bino(trialEnd,window_order)) / frameRate; 
R.gaze_bino_frac = R.gaze_bino_s / analysis_end;

R.gaze_L_s = double(trackingData_struct.cumulative_gaze_left(trialEnd,window_order)) / frameRate; 
R.gaze_L_frac = R.gaze_L_s / analysis_end;

R.gaze_R_s = double(trackingData_struct.cumulative_gaze_right(trialEnd,window_order)) / frameRate; 
R.gaze_R_frac = R.gaze_R_s / analysis_end;

R.body_s = double(trackingData_struct.cumulative_body(trialEnd,window_order)) / frameRate; 
R.body_frac = R.body_s / analysis_end;

R.window_visibility_s = sum(trackingData_struct.window_visibility(trialStart:trialEnd, window_order)) / frameRate;
R.window_visibility_frac = R.window_visibility_s / analysis_end;

R.pause_visibility_frac = sum(trackingData_struct.window_visibility(R.pause_frames, window_order)) / length(R.pause_frames);

Ncontacts = [length(contact_frames_A), length(contact_frames_B), length(contact_frames_C)];
R.Ncontacts = Ncontacts(window_order);

median_contact_dur = [nanmedian(double(contact_widths_A/frameRate)), nanmedian(double(contact_widths_B/frameRate)), nanmedian(double(contact_widths_C/frameRate))];
R.median_contact_dur = median_contact_dur(window_order);

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