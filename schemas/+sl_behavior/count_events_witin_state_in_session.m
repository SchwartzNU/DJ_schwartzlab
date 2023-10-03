function [count_in_state, state_frac_of_target] = count_events_witin_state_in_session(event_id, target_type, modifier_target, state_type, modifier_state)
if nargin<5
    modifier_state = [];
end

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

target_frames = fetchn(q,'frame');

target_in_state_frames = intersect(target_frames,state_frames);

count_in_state = length(target_in_state_frames);

state_frac_of_target = length(target_in_state_frames) ./ length(target_frames);

