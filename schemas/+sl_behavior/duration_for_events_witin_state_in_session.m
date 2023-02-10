function [target_frac_of_state, state_frac_of_target, target_time, session_frac] = duration_for_events_witin_state_in_session(event_id, target_type, modifier_target, state_type, modifier_state)
if nargin<5
    modifier_state = [];
end

frame_rate = 15; %frames per second: TODO read this in from some preference file

if isempty(modifier_state)
    q = sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        sprintf('annotation_name="%s"', state_type);
else
    q = sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        sprintf('annotation_name="%s"', state_type) & ...
        sprintf('modifier="%s"', modifier_state);
end

state_frames = sl_behavior.frames_in_query(q);

if isempty(modifier_target)
    q = sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        sprintf('annotation_name="%s"', target_type);
else
    q = sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        sprintf('annotation_name="%s"', target_type) & ...
        sprintf('modifier="%s"', modifier_target);
end

start_frame = fetch1(sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        'annotation_name="door open"', 'frame');

last_frame = fetch1(aggr(sln_animal.SocialBehaviorSession & sprintf('event_id=%d', event_id), ...
    sl_behavior.Annotation & sprintf('event_id=%d', event_id), ...
    'max(frame)->max_frame'), 'max_frame');

total_time = double(last_frame - start_frame) / frame_rate;

target_frames = sl_behavior.frames_in_query(q);

target_in_state_frames = intersect(target_frames,state_frames);

target_frac_of_state = length(target_in_state_frames) ./ length(state_frames);

state_frac_of_target = length(target_in_state_frames) ./ length(target_frames);

target_time = length(target_in_state_frames) / frame_rate;

session_frac = target_time / total_time;
