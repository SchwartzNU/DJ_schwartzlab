function delay_s = time_to_first_event_in_session(event_id, annotation_type, modifier)
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

first_frame = min(fetchn(q,'frame'));

start_frame = fetch1(sl_behavior.Annotation & ...
        sprintf('event_id=%d', event_id) & ...
        'annotation_name="door open"', 'frame');


delay_s = double(first_frame - start_frame) / frame_rate;
