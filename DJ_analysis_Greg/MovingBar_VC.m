function R = MovingBar_VC(data_group, params)
if nargin < 2 || isempty(params)
    binSize = 10;
else
    binSize = params.binSize;
end

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = table('Size',[N_datasets, 41], 'VariableNames', ...
    {'file_name', ...
    'dataset_name', ...
    'source_id', ...
    'bar_angles', ...
    'bar_length', ...
    'bar_speed', ...
    'bar_width', ...
    'bar_distance', ...
    'sample_rate', ...
    'pre_time_ms', ...
    'stim_time_ms', ...
    'tail_time_ms', ...
    'n_epochs_per_angle', ...
    'peak_full_mean', ...
    'peak_leading_mean', ...
    'peak_trailing_mean', ...
    'peak_full_sem', ...
    'peak_leading_sem', ...
    'peak_trailing_sem', ...    
    'charge_full_mean', ...
    'charge_leading_mean', ...
    'charge_trailing_mean', ...
    'charge_full_sem', ...
    'charge_leading_sem', ...
    'charge_trailing_sem', ...    
    'mean_traces_by_angle', ...
    'leading_trailing_index_peak', ...
    'leading_trailing_index_charge', ...
    'dsi_peak', ...
    'ds_ang_peak', ...
    'dsi_leading_peak', ...
    'ds_ang_leading_peak', ...
    'dsi_trailing_peak', ...
    'ds_ang_trailing_peak', ...
    'dsi_charge', ...
    'ds_ang_charge', ...
    'dsi_leading_charge', ...
    'ds_ang_leading_charge', ...
    'dsi_trailing_charge', ...
    'ds_ang_trailing_charge', ...
    'holding_current_mean'...
    }, ...
    'VariableTypes', ...
    {'string', ...
    'string', ...
    'uint16', ...
    'cell', ...
    'uint32', ...
    'uint16', ...
    'uint16', ...
    'uint16', ...
    'uint16', ...
    'uint16', ...
    'uint16', ...
    'uint16', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'singlenan', ...
    'double'...
    });

%assign UserData of table to be the table name
R.Properties.UserData = 'MovingBar_VC';

%assign test descriptions for some of the variables 
R.Properties.VariableDescriptions = ...
    {'file name from symphony', ...
    'dataset name', ... 
    'source id used to identify the cell to which the dataset belongs', ...
    'set of bar angles (degrees)', ...
    'bar length (microns)', ... %along axis of motion
    'bar speed (microns per second)', ...
    'bar width (microns', ... %orthogonal to axis of motion
    'travel distance (microns)', ...
    'sample_rate (Hz)', ...   
    'time before stimulus onset (ms)', ...
    'stimulus presentation time (ms)', ...
    'time after stimulus offset (ms)', ...
    'vector with how many trials for each angle', ...
    'peak current during bar movement mean (pA)', ...
    'peak current during first half of bar movement (leading edge), mean (pA)', ...
    'peak current during second half of bar movement (trailing edge), mean (pA)', ...
    'peak current during bar movement sem (pA)', ...
    'peak current during first half of bar movement (leading edge), sem (pA)', ...
    'peak current during second half of bar movement (trailing edge), sem (pA)', ...
    'total charge during bar movement mean (pC)', ...
    'total charge  during first half of bar movement (leading edge), mean (pC)', ...
    'total charge  during second half of bar movement (trailing edge), mean (pC)', ...
    'total charge during bar movement sem (pC)', ...
    'total charge  during first half of bar movement (leading edge), sem (pC)', ...
    'total charge  during second half of bar movement (trailing edge), sem (pC)', ...
    'mean trace for each bar angle', ...
    'peak-based index defined as (leading - trailing) / (leading + trailing)', ...
    'charge-based index defined as (leading - trailing) / (leading + trailing)', ...
    'peak-based vector sum dsi for the full movement period', ...
    'peak-based ds angle for the full movement period (degrees)', ...
    'peak-based vector sum dsi for the leading period', ...
    'peak-based ds angle for the leading period (degrees)', ...
    'peak-based vector sum dsi for the trailing period', ...
    'peak-based ds angle for the trailing period (degrees)', ...
    'charge-based vector sum dsi for the full movement period', ...
    'charge-based ds angle for the full movement period (degrees)', ...
    'charge-based vector sum dsi for the leading period', ...
    'charge-based ds angle for the leading period (degrees)', ...
    'charge-based vector sum dsi for the trailing period', ...
    'charge-based ds angle for the trailing period (degrees)', ...
    'mean holding current (pA)' ...
    };

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        sln_symphony.ExperimentProtocolMovingBarV1BlockParameters * ...
        sln_symphony.ExperimentProtocolMovingBarV1EpochParameters & ...
        datasets_struct(d),'*');
    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    sample_rate = epochs_in_dataset(1).sample_rate;

    %parameters to save for the whole dataset
    %rstar_mean = epochs_in_dataset(1).rstar_mean;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
    stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
    tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
    total_samples = pre_samples + stim_samples + tail_samples;

    bar_length = epochs_in_dataset(1).bar_length;
    bar_width = epochs_in_dataset(1).bar_width;
    bar_speed = epochs_in_dataset(1).bar_speed;
    bar_distance = epochs_in_dataset(1).distance;

    screenMidPoint = bar_distance/2;
    barMidPoint = bar_length/2;
    timeToMidPoint_samples = pre_samples + (sample_rate * (screenMidPoint+barMidPoint)) / bar_speed; %ms
    
    all_angles = round([epochs_in_dataset.bar_angle]);
    bar_angles = sort(unique(all_angles));
    N_angles = length(bar_angles); 

    N_epochs_per_angle = zeros(N_angles,1);

    peak_full_mean = zeros(N_angles,1);
    peak_leading_mean = zeros(N_angles,1);
    peak_trailing_mean = zeros(N_angles,1);
    peak_full_sem = zeros(N_angles,1);
    peak_leading_sem = zeros(N_angles,1);
    peak_trailing_sem = zeros(N_angles,1);
    charge_full_mean = zeros(N_angles,1);
    charge_leading_mean = zeros(N_angles,1);
    charge_trailing_mean = zeros(N_angles,1);
    charge_full_sem = zeros(N_angles,1);
    charge_leading_sem = zeros(N_angles,1);
    charge_trailing_sem = zeros(N_angles,1);
    leading_trailing_index_peak = zeros(N_angles,1);
    leading_trailing_index_charge = zeros(N_angles,1);

    holding_current_vector = zeros(N_angles,1);
    mean_traces_by_angle = zeros(N_angles,total_samples);

    for s=1:N_angles
        ind = find(all_angles == bar_angles(s));
        N_epochs_per_angle(s) = length(ind);
        peak_full = zeros(N_epochs_per_angle(s),2);
        peak_leading = zeros(N_epochs_per_angle(s),2);
        peak_trailing = zeros(N_epochs_per_angle(s),2);
        charge_full = zeros(N_epochs_per_angle(s),1);
        charge_leading = zeros(N_epochs_per_angle(s),1);
        charge_trailing = zeros(N_epochs_per_angle(s),1);

        mean_traces_by_angle(s,:) = mean(reshape([epochs_in_dataset(ind).raw_data], [], length(ind)), 2)';
        holding_current_vector(s) = mean(mean_traces_by_angle(s,1:pre_samples));
        for i=1:N_epochs_per_angle(s)
            trace = epochs_in_dataset(ind(i)).raw_data;
            baseline = mean(trace(1:pre_samples));
            trace_baseline_subtraced = trace - baseline;
            peak_full(i,1) = min(trace_baseline_subtraced(pre_samples+1:pre_samples+stim_samples));
            peak_full(i,2) = max(trace_baseline_subtraced(pre_samples+1:pre_samples+stim_samples));
            peak_leading(i,1) = min(trace_baseline_subtraced(pre_samples+1:timeToMidPoint_samples));
            peak_leading(i,2) = max(trace_baseline_subtraced(pre_samples+1:timeToMidPoint_samples));
            peak_trailing(i,1) = min(trace_baseline_subtraced(timeToMidPoint_samples+1:pre_samples+stim_samples));
            peak_trailing(i,2) = max(trace_baseline_subtraced(timeToMidPoint_samples+1:pre_samples+stim_samples));         
            charge_full(i) = sum(trace_baseline_subtraced(pre_samples+1:pre_samples+stim_samples))/sample_rate;
            charge_leading(i) = sum(trace_baseline_subtraced(pre_samples+1:timeToMidPoint_samples))/sample_rate;
            charge_trailing(i) = sum(trace_baseline_subtraced(timeToMidPoint_samples+1:pre_samples+stim_samples))/sample_rate;
        end

        if abs(mean(peak_full(:,1))) > abs(mean(peak_full(:,2)))
            peak_full_mean(s) = mean(peak_full(:,1));
            peak_full_sem(s) = std(peak_full(:,1)) ./ sqrt(N_epochs_per_angle(s)-1);
        else
            peak_full_mean(s) = mean(peak_full(:,2));
            peak_full_sem(s) = std(peak_full(:,2)) ./ sqrt(N_epochs_per_angle(s)-1);
        end
        if abs(mean(peak_leading(:,1))) > abs(mean(peak_leading(:,2)))
            peak_leading_mean(s) = mean(peak_leading(:,1));
            peak_leading_sem(s) = std(peak_leading(:,1)) ./ sqrt(N_epochs_per_angle(s)-1);
        else
            peak_leading_mean(s) = mean(peak_leading(:,2));
            peak_leading_sem(s) = std(peak_leading(:,2)) ./ sqrt(N_epochs_per_angle(s)-1);
        end
        if abs(mean(peak_trailing(:,1))) > abs(mean(peak_trailing(:,2)))
            peak_trailing_mean(s) = mean(peak_trailing(:,1));
            peak_trailing_sem(s) = std(peak_trailing(:,1)) ./ sqrt(N_epochs_per_angle(s)-1);
        else
            peak_trailing_mean(s) = mean(peak_trailing(:,2));
            peak_trailing_sem(s) = std(peak_trailing(:,2)) ./ sqrt(N_epochs_per_angle(s)-1);
        end
        
        charge_full_mean(s) = mean(charge_full);
        charge_full_sem(s) = std(charge_full) ./ sqrt(N_epochs_per_angle(s)-1);
        charge_leading_mean(s) = mean(charge_leading);
        charge_leading_sem(s) = std(charge_leading) ./ sqrt(N_epochs_per_angle(s)-1);
        charge_trailing_mean(s) = mean(charge_trailing);
        charge_trailing_sem(s) = std(charge_trailing) ./ sqrt(N_epochs_per_angle(s)-1);

        leading_trailing_index_peak(s) = (peak_leading_mean(s) - peak_trailing_mean(s)) / (peak_leading_mean(s) + peak_trailing_mean(s));
        leading_trailing_index_charge(s) = (charge_leading_mean(s) - charge_trailing_mean(s)) / (charge_leading_mean(s) + charge_trailing_mean(s));
    end

    holding_current_mean = mean(holding_current_vector);

    ds_struct_peak = computeDSIandOSI(bar_angles, abs_rectify(peak_full_mean'));
    ds_struct_leading_peak = computeDSIandOSI(bar_angles, abs_rectify(peak_leading_mean'));
    ds_struct_trailing_peak = computeDSIandOSI(bar_angles, abs_rectify(peak_trailing_mean'));
    ds_struct_charge = computeDSIandOSI(bar_angles, abs_rectify(charge_full_mean'));
    ds_struct_leading_charge = computeDSIandOSI(bar_angles, abs_rectify(charge_leading_mean'));
    ds_struct_trailing_charge = computeDSIandOSI(bar_angles, abs_rectify(charge_trailing_mean'));

    %set table variables
    R.dsi_peak(d) = ds_struct_peak.DSI;
    R.ds_ang_peak(d) = ds_struct_peak.DSang;
    R.dsi_leading_peak(d) = ds_struct_leading_peak.DSI;
    R.ds_ang_leading_peak(d) = ds_struct_leading_peak.DSang;
    R.dsi_trailing_peak(d) = ds_struct_trailing_peak.DSI;
    R.ds_ang_trailing_peak(d) = ds_struct_trailing_peak.DSang;
    R.dsi_charge(d) = ds_struct_charge.DSI;
    R.ds_ang_charge(d) = ds_struct_charge.DSang;
    R.ds_ang_leading_charge(d) = ds_struct_leading_charge.DSI;
    R.ds_ang_leading_charge(d) = ds_struct_leading_charge.DSang;
    R.dsi_trailing_charge(d) = ds_struct_trailing_charge.DSI;
    R.ds_ang_trailing_charge(d) = ds_struct_trailing_charge.DSang;
    
    R.file_name(d) = datasets_struct(d).file_name;
    R.dataset_name(d) = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.bar_angles(d) = {bar_angles'};
    R.bar_length(d) = bar_length;
    R.bar_speed(d) = bar_speed;
    R.bar_width(d) = bar_width;
    R.bar_distance(d) = bar_distance;
    R.sample_rate(d) = sample_rate;
    R.pre_time_ms(d) = pre_stim_tail.pre_time;
    R.stim_time_ms(d) = pre_stim_tail.stim_time;
    R.tail_time_ms(d) = pre_stim_tail.tail_time;
    R.peak_full_mean(d) = {peak_full_mean};
    R.peak_leading_mean(d) = {peak_leading_mean};
    R.peak_trailing_mean(d) = {peak_trailing_mean};
    R.peak_full_sem(d) = {peak_full_sem};
    R.peak_leading_sem(d) = {peak_leading_sem};
    R.peak_trailing_sem(d) = {peak_trailing_sem};
    R.charge_full_mean(d) = {charge_full_mean};
    R.charge_leading_mean(d) = {charge_leading_mean};
    R.charge_trailing_mean(d) = {charge_trailing_mean};
    R.charge_full_sem(d) = {charge_full_sem};
    R.charge_leading_sem(d) = {charge_leading_sem};
    R.charge_trailing_sem(d) = {charge_trailing_sem};
    R.mean_traces_by_angle(d) = {mean_traces_by_angle};
    R.n_epochs_per_angle(d) = {N_epochs_per_angle};
    R.leading_trailing_index_peak(d) = {leading_trailing_index_peak};
    R.leading_trailing_index_charge(d) = {leading_trailing_index_charge};
    R.holding_current_mean(d) = holding_current_mean;
    fprintf('Elapsed time = %d seconds\n', round(toc));
end