function R = behaviorSessionAnalysis2D(session_id, P)
R = struct;
%analysis parameters
analysis_end = P.analysis_end; %time in seconds after mouse exist chamber to stop analysis
nose_contact_thres = P.nose_contact_thres; %threshold (pixels) for counting a nose contact
nose_contact_duration_thres = P.nose_contact_duration_thres; %threshold (seconds) for counting a nose contact
window_order = P.window_order; %3 element vector specifying how to order the windows

frameRate = 15; %Hz, TODO, load from calibration
cm_per_pixel = .056; %TODO, load from calibration

nose_data = fetch(sl_behavior.NoseData2D & sprintf('event_id=%d',session_id),'*')
gaze_data = fetch(sl_behavior.GazeData2D & sprintf('event_id=%d',session_id),'*');
calibration = fetch(sl_behavior.TopCameraCalibration & sprintf('event_id=%d',session_id),'*');

Nframes = size(nose_data.nose_position_from_center,1)
if isempty(nose_data)
    fprintf('No data found for session %d. Skipping.\n', session_id);
    return;
end
speed = zeros(Nframes,1);
for i=2:Nframes
    speed(i) = pdist2(nose_data.nose_position_from_center(i,:),nose_data.nose_position_from_center(i-1,:));    
end

speed_cm_per_s = speed*cm_per_pixel*frameRate;

trialStart = find(~isnan(gaze_data.bino_gaze_outer_wall),1);
trialEnd = trialStart + round(analysis_end*frameRate-1);

[~, contact_frames, contact_widths] = findpeaks(-nose_data.distance_from_window,'MinPeakHeight', -nose_contact_thres, 'MinPeakWidth', nose_contact_duration_thres*frameRate);

if trialEnd > Nframes
    disp(['Warning: ' num2str(analysis_end) ' after mouse exits chamber is past end of recording.']);
    trialEnd = Nframes-1;
    analysis_end = (trialEnd - trialStart) / frameRate;
end

R.meanSpeed = nanmean(speed_cm_per_s(trialStart:trialEnd));

gaze_frames = [length(gaze_data.win_a_gaze_frames), ...
    length(gaze_data.win_b_gaze_frames), ...
    length(gaze_data.win_c_gaze_frames)];
gaze_frames = gaze_frames(window_order);
R.gaze_bino_s = gaze_frames / frameRate;
R.gaze_bino_frac = R.gaze_bino_s / analysis_end;

body_sector = [sum(nose_data.closest_window(trialStart:trialEnd)==1), ...
    sum(nose_data.closest_window(trialStart:trialEnd)==2), ...
    sum(nose_data.closest_window(trialStart:trialEnd)==3)];
body_sector = body_sector(window_order);
R.body_s = body_sector / frameRate;
R.body_frac = R.body_s / analysis_end;

Ncontacts = [length(intersect(contact_frames,find(nose_data.closest_window==1))), ...
    length(intersect(contact_frames,find(nose_data.closest_window==2))), ...
    length(intersect(contact_frames,find(nose_data.closest_window==3)))];
R.Ncontacts = Ncontacts(window_order);
R.Ncontacts_per_min = 60 * R.Ncontacts./analysis_end;

contact_dur = [median(contact_widths(find(intersect(contact_frames,find(nose_data.closest_window==1))))), ...
    median(contact_widths(find(intersect(contact_frames,find(nose_data.closest_window==2))))), ...
    median(contact_widths(find(intersect(contact_frames,find(nose_data.closest_window==3)))))];
R.median_contact_dur = contact_dur(window_order)./frameRate;


