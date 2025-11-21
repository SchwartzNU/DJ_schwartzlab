function required_fields = plot_psc_detection(R, ax)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if nargin < 1
    required_fields = {'psc_start_ms', 'sample_rate'};
    return;
end

%fetching raw trace from database
q.file_name =char(R.file_name);
q.source_id = R.source_id;
q.epoch_id = R.epoch_id;
%only plot Amp1 raw data, change if data is fron amp2
q.channel_name = 'Amp1';
data = fetch(sln_symphony.ExperimentEpochChannel&q, 'raw_data');

%plotting the detection

x_axis = linspace(0, numel(data.raw_data)/R.sample_rate, numel(data.raw_data));
%plot(x_axis, data.raw_data, 'Color', 'black');
plot(ax, x_axis, data.raw_data, 'Color', 'black');
%hold on;
hold(ax, 'on');
[~, psc_n] = size(R.psc_start_ms);
for i = 1:psc_n
    timing = R.psc_start_ms(i);
    %xline(timing, '-', 'Color', 'blue');
    xline(ax, timing, '-', 'Color', 'blue');
end
ylabel(ax, 'Synpatic current (pA)');
xlabel(ax, 'Time (s)');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
hold(ax, 'off');
%hold off;
end