function [d_total, d_mean, frac] = duration_for_events_in_session(event_id, annotation_type, modifier)
if nargin<3
    modifier = [];
end

frame_rate = 15; %frames per second: TODO read this in from some preference file

if isempty(modifier)
    q = sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        sprintf('annotation_name="%s"', annotation_type);
else
    q = sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        sprintf('annotation_name="%s"', annotation_type) & ...
        sprintf('modifier="%s"', modifier);
end

d_total = fetch1(aggr(sln_animal.SocialBehaviorSession & sprintf('event_id=%d', event_id), ...
    q, 'sum(duration)->dur'), 'dur');

d_mean = fetch1(aggr(sln_animal.SocialBehaviorSession & sprintf('event_id=%d', event_id), ...
    q, 'avg(duration)->dur'), 'dur');

start_frame = fetch1(sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        'annotation_name="door open"', 'frame');

last_frame = fetch1(aggr(sln_animal.SocialBehaviorSession & sprintf('event_id=%d', event_id), ...
    sl_behavior.Annotation & sprintf('event_id=%d', event_id), ...
    'max(frame)->max_frame'), 'max_frame');

total_time = double(last_frame - start_frame) / frame_rate;

d_total = d_total / frame_rate;
d_mean = d_mean / frame_rate;
frac = d_total / total_time;
