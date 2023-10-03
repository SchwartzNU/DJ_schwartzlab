function c = count_events_in_session(event_id, annotation_type, modifier)
if nargin<3
    modifier = [];
end

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

c = q.count;