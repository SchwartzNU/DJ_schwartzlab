function [] = sessionDiaryPlot(session_id, which_calls)
if nargin<2
    which_calls = 'all';
end

squeak_query = sl_behavior.Squeaks & sprintf('event_id=%d',session_id);
if ~squeak_query.exists
    disp('Squeak table entry not found for this session');
    return;
end
squeak_data = fetch(squeak_query, '*');

annotation_query = sl_behavior.Annotation & sprintf('event_id=%d',session_id);
if ~annotation_query.exists
    disp('Annotations not found for this session');
    return;
end
annotation_data = fetch(annotation_query, '*');

tracking_query = sl_behavior.TrackingData2D & sprintf('event_id=%d',session_id);
if ~tracking_query.exists
    disp('TrackingData2D table entry not found for this session');
    return;
end
tracking_data = fetch(tracking_query, '*');

frame_rate = 15; %Hz;
time_axis = linspace(0,(tracking_data.n_frames-1)/frame_rate,tracking_data.n_frames);

figure;
plot(time_axis,zeros(size(time_axis)));
ax = gca;
hold('on');
for i=1:length(annotation_data)
    event_time = annotation_data(i).frame / frame_rate;        
    ypos = 1 - event_time/(tracking_data.n_frames/frame_rate);
    if strcmp(annotation_data(i).annotation_name,'door open')        
        line([event_time, event_time], [0, 1], 'Color','k','LineWidth',2);
        text(event_time, ypos, 'Door open');
    elseif  strcmp(annotation_data(i).annotation_name,'retrieve pup')
        line([event_time, event_time], [0, 1], 'Color', 'r','LineWidth',2);
        text(event_time, ypos, annotation_data(i).modifier);
    elseif strcmp(annotation_data(i).annotation_name,'drop pup')
        line([event_time, event_time], [0, 1], 'Color','r','LineStyle','--','LineWidth',2);
        text(event_time, ypos, annotation_data(i).modifier);
    end
end
xlabel('Time (s)');

if strcmp(which_calls, 'all')
    N_call_types = 10;
    call_ids = 0:9;
elseif strcmp(which_calls, 'adult')
    N_call_types = 5;
    call_ids = 5:9;
elseif strcmp(which_calls, 'pup')
    N_call_types = 5;
    call_ids = 0:4;
end

cmap = colormap(ax,'parula');
color_ind = round(linspace(1,256,N_call_types));

for i=1:N_call_types
    ind = find(squeak_data.call_types == call_ids(i));
    for c=1:length(ind)
        call_time = squeak_data.call_times(ind(c));
        plot(call_time, 0.9 * i./N_call_types,'x',...
            'Color',cmap(color_ind(i),:),'LineWidth',2);        
    end
end

cbar = colorbar(ax,'Ticks',linspace(0,1,N_call_types),'TickLabels',strsplit(num2str(call_ids)));
cbar.Label.String = 'Call type';
hold('off');

