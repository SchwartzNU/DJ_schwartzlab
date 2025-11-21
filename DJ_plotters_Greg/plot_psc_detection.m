function required_fields = plot_psc_detection(R, ax)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if nargin < 1
    required_fields = {'psc_start_ms', 'sample_rate'};
    return;
end

%fetching raw trace from database
q.file_name = R.file_name;
q.source_id = R.source_id;
q.epoch_id = R.epoch_id;
%only plot Amp1 raw data, change if data is fron amp2
q.channel_name = 'Amp1';
data = fetch(sln_symphony.ExperimentEpochChannel&q, 'raw_data');

%plotting the detection
plot(ax, data.raw_data);
hold(ax, 'on');
[~, psc_n] = size(R.psc_start_ms);
for i = 1:psc_n
    timing = R.psc_start_ms/1000*R.sample_rate;
    xline(ax, timing, '-', 'Color', 'blue');
end
ylabel(ax, 'Synpatic current (pA)');
hold(ax, 'off');
end