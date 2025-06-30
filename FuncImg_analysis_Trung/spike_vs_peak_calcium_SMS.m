function result_struct = spike_vs_peak_calcium_SMS(alignment)
    big_querry = sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentElectrode * ...
        sln_symphony.ExperimentEpochChannel * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.SpikeTrain * ...
        aka.SMSparams * ...
        sln_funcimage.ROITraces ...
        & alignment;
    cell_name = fetch1(sln_cell.CellName & alignment, 'cell_name');
    cell_type = fetch1(sln_cell.AssignType.current & (sln_cell.Cell & alignment), 'cell_type');
    dataset_name = fetch1(sln_symphony.Dataset & alignment, 'dataset_name');

    result_struct.cell_name = cell_name;
    result_struct.cell_type = cell_type;

    epoch_data = fetch(big_querry, '*');
    %imaging parts
    raw_img_trace = vertcat(epoch_data.traces);
    img_time_axis = [0 : size(raw_img_trace, 2) - 1] ./ 1000; %ms

    %spike partsstart_time
    raw_data = vertcat(epoch_data.raw_data); %maybe not needed?
    sample_rate = epoch_data(1).sample_rate;
    start_time = epoch_data(1).pre_time; %ms
    end_time = epoch_data(1).pre_time + epoch_data(1).stim_time; %ms
    start_point = start_time * sample_rate / 1000;
    end_point = end_time * sample_rate / 1000; 
    %turn spike_count into spike raster
    spike_indices = {epoch_data.spike_indices};
    spike_raster = zeros(size(raw_data));
    time_axis = [0:size(raw_data,2) - 1] ./ sample_rate; 
    
    base_line_spike_count = zeros(size(raw_data, 1), 1);
    stim_spike_count = zeros(size(raw_data, 1), 1);
    tail_spike_count = zeros(size(raw_data, 1), 1);
    for i = 1:size(raw_data, 1)
        spike_raster(i, spike_indices{i}) = 1;
        base_line_spike_count(i) = sum(spike_raster(i, 1:start_point-1)) / (start_time / 1000);
        stim_spike_count(i) = sum(spike_raster(i, start_point:end_point-1)) / (epoch_data(1).stim_time / 1000);
        tail_spike_count(i) = sum(spike_raster(i, end_point:end)) / 0.5; % only looking at the last 500 ms
    end

    delta_spike_stim = stim_spike_count - base_line_spike_count;
    delta_spike_tail = tail_spike_count - base_line_spike_count;


    max_calcium_stim = zeros(size(raw_img_trace, 1), 1);
    max_calcium_tail = zeros(size(raw_img_trace, 1), 1);
    %convert calcium to delta F/F0
    img_trace_normalized = zeros(size(raw_img_trace));
    for i = 1:size(raw_img_trace, 1)
        F_0 = mean(raw_img_trace(i, 1:start_time-1));
        img_trace_normalized(i, :) = (raw_img_trace(i, :) - F_0) ./ F_0;
        max_calcium_stim(i) = max(img_trace_normalized(i, start_time:end_time));
        max_calcium_tail(i) = max(img_trace_normalized(i, end_time:end));
    end

    result_struct.spike_raster = spike_raster;
    result_struct.dataset_name = dataset_name;
    result_struct.img_trace_normalized = img_trace_normalized;
    result_struct.img_time_axis = img_time_axis;
    result_struct.time_axis = time_axis;
    result_struct.base_line_spike_count = base_line_spike_count;
    result_struct.stim_spike_count = stim_spike_count;
    result_struct.tail_spike_count = tail_spike_count;
    result_struct.delta_spike_stim = delta_spike_stim;
    result_struct.delta_spike_tail = delta_spike_tail;
    result_struct.max_calcium_stim = max_calcium_stim;
    result_struct.max_calcium_tail = max_calcium_tail;
    

end