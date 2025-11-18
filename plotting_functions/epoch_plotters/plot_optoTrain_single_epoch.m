function plot_optoTrain_single_epoch(raw_data_struct)
%getting epoch parameters from database
stimq.file_name = raw_data_struct.file_name;
stimq.source_id = raw_data_struct.source_id;
stimq.epoch_group_id = raw_data_struct.epoch_group_id;
stimq.epoch_block_id = raw_data_struct.epoch_block_id;

stim_params = fetch(sln_symphony.ExperimentProtOptopulseTrainV1bp & stimq, '*');

%get sample rate
stimq.channel_name = 'Amp1';
electrode_params = fetch(sln_symphony.ExperimentChannel & stimq, 'sample_rate');

if (isempty(stim_params) || isempty(electrode_params))
    fprintf('No epoch found for data: ');
    disp(raw_data_struct);
else
    %plotting
    figure;
    fig = gcf;
    fig.Units = 'inches';
    fig.Position = [2,2,8,4];

    ydata = raw_data_struct.raw_data;
    total_time = numel(raw_data_struct.raw_data);
    total_time = total_time/electrode_params.sample_rate;
    xdata = linspace(0, total_time, numel(ydata));
    plot(xdata, ydata, 'Color', 'black');
    hold on;
    
    %put vertical lines where pulse comes on and off
    for i = 1:stim_params.num_pulses
        startline = (i-1)*(stim_params.downtime + stim_params.pulse_time) + stim_params.pre_time;
        endline = (startline + stim_params.pulse_time)/1000;
        startline = startline/1000;
        xline(startline, '--r', 'LineWidth', 0.1);
        xline(endline, '--b', 'LineWidth', 0.1);
    end

    %adding axes lables 
    xlabel('Time (s)');
    ylabel('Postsynaptic current amplitude (pA)');

end

end