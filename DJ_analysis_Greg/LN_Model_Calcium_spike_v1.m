function R = LN_Model_Calcium_spike_v1(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

%R = sln_results.table_definition_from_template('LN_Model_Calcium_spike_v1',N_datasets);

for d=1:N_datasets
    %try
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);
    
    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.MultiPulseParams * sln_funcimage.ROITraces * sln_funcimage.ImagingRun * aka.SpikeTrain & ...
        'channel_name="Amp1"' & ...
        datasets_struct(d),'*');
    
    N_epochs = length(epochs_in_dataset);
    if N_epochs == 0
        warning('No epochs or imaging not run in dataset: %s', datasets_struct(d).dataset_name);
    end
    
    %parameters to save for the whole dataset
    sample_rate = epochs_in_dataset(1).sample_rate;
    frame_rate = epochs_in_dataset(1).frame_rate;
    %rstar_mean = epochs_in_dataset(1).rstar_mean;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_1_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
    stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
    tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
    total_samples = pre_samples + stim_samples + tail_samples;
    
    raw_data = vertcat(epochs_in_dataset.raw_data);
    delta_spike = nan(size(raw_data, 1), 1);
    voltage = movmedian(raw_data, 500, 2);
    spikes = zeros(size(raw_data));
    currents = [epochs_in_dataset.pulse_1_curr];
    
    MIN_PEAK_DISTANCE = 0.001 * sample_rate;
    MIN_PEAK_HEIGHT = -5;
    for i=1:size(raw_data,1)
        [~, locs] = findpeaks(raw_data(i,:),"MinPeakHeight", -5, 'MinPeakProminence', 5, 'MinPeakDistance', MIN_PEAK_DISTANCE);
        
        spikes(i, locs) = 1;
        
        spike_pre_stim = findpeaks(raw_data(i,1:pre_samples),"MinPeakHeight", MIN_PEAK_HEIGHT, 'MinPeakProminence', 5, 'MinPeakDistance', MIN_PEAK_DISTANCE);
        spike_stim = findpeaks(raw_data(i,pre_samples: (pre_samples + stim_samples)),"MinPeakHeight", MIN_PEAK_HEIGHT, 'MinPeakProminence', 5, 'MinPeakDistance', MIN_PEAK_DISTANCE);
        delta_spike(i, 1) = length(spike_stim) - length(spike_pre_stim);
        
    end
    
    spikes_calcium_filtered = movmean(spikes, 1500, 2) * 50000 / 1500 * 1e3;
    
    calcium_signal = vertcat(epochs_in_dataset.traces);
    
    
    
    %normalized F/F0 copied from meanForROI
    time_points = size(epochs_in_dataset(1).traces,2);
    trace_matrix = zeros(size(calcium_signal));
    time_axis = (1:time_points) - epochs_in_dataset(1).pre_time;
    pre_pts = time_axis < 0;
    
    for i=1:N_epochs
        
        
        baseline = mean(calcium_signal(i,pre_pts));
        trace_matrix(i,:) = (calcium_signal(i,:) - baseline) ./ baseline;
        
        
    end
    
    max_calcium_signal = max(trace_matrix');
    
    %% resampling to 100Hz;
    spike_time_array = [0:size(raw_data,2)-1] / sample_rate ; % second
    cal_time_array = (0:time_points-1) / 1e3;
    spikes_data = resample(spikes_calcium_filtered', spike_time_array, 100);
    cal_data = resample(trace_matrix', cal_time_array, 100);
    
    
    data_size = size(spikes_data, 2);
    split_ratio = [0.3 , 0.4 , 0.3];
    idx = randperm(data_size);
    train_idx_filter = idx(1:round(split_ratio(1) * data_size));
    train_idx_nl = idx(round(split_ratio(1) * data_size) + 1 : (round(split_ratio(1) * data_size) + round(split_ratio(2) * data_size)));
    test_idx = setdiff(idx,[train_idx_filter, train_idx_nl]);
    spike_training = spikes_data(:,train_idx_filter)';
    spike_test = spikes_data(:, test_idx)';
    spike_training_nl = spikes_data(:, train_idx_nl)';
    
    cal_training = cal_data(:,train_idx_filter)';
    cal_test = cal_data(:, test_idx)';
    cal_training_nl = cal_data(:, train_idx_nl)';
    
    %% LN
    
    filt_f = zeros(size(train_idx_filter,2), size(cal_training, 2));
    for i=1:size(cal_training,1)
        offset = mean(cal_training(i,:));
        cal_training_temp = fliplr(cal_training(i,:) - offset);
        spike_training_temp = fliplr(spike_training(i,:) - mean(spike_training(i,:)));
        L = length(cal_training_temp);
        
        freq = 100*(0:(L/2))/L;
        
        filt_f(i,:) = fft(spike_training_temp) .* conj(fft(cal_training_temp));
        
        
    end
    

    filt_t = real(ifft(mean(filt_f,1)));
    filt_t = filt_t / abs(max(filt_t));
   
    max_pred = nan(size(train_idx_nl,2),1);
    max_train_nl = nan(size(train_idx_nl,2),1);
    for i = 1: size(train_idx_nl,2)
         
        cal_test_temp = fliplr(cal_training_nl(i,:) - mean(cal_training_nl(i,:)));
        
        pred = conv(cal_test_temp, fliplr(filt_t(1:150)), 'same');
        max_pred(i) = max(pred);
        max_train_nl(i) = max(spike_training_nl(i, :)); 
        
    end
    
    max_test_pred = nan(size(test_idx,2),1);
    max_test_truth = nan(size(test_idx,2),1);
    for i = 1:size(test_idx,2)
        cal_test_temp = fliplr(cal_test(i,:) - mean(cal_test(i,:)));
        
        pred = conv(cal_test_temp, fliplr(filt_t(1:150)), 'same');
        max_test_pred(i) = max(pred);
        max_test_truth(i) = max(spike_test(i, :)); 
    
    end

    % NL fit part
    max_test_pred_LN = interp1(max_pred, max_train_nl, max_test_pred, 'nearest' ,'extrap');

    f = figure; tiledlayout(2,2);
    f.Position([3,4]) = [850, 700];
    f.Color = [1,1,1];
    nexttile;
    plot(filt_t, 'LineWidth', 3);
    box off;
    title(data_group(d).image_fname, 'Interpreter', 'none');
    nexttile; hold on;
    scatter(max_pred, max_train_nl, 100, 'filled', 'HandleVisibility', 'off');
    xlabel('Max prediction (training NL)');
    ylabel('Max truth (training NL)');
    test_line = linspace(0,max(max_pred), 10);
    y_test_line = interp1(max_pred, max_train_nl, test_line, 'nearest' ,'extrap');
    plot(test_line, y_test_line, ':', 'LineWidth', 2, 'DisplayName', 'Interp1 fit line');
    legend('Location','best');
    nexttile;hold on;
    test_curr = currents(test_idx);
    depol_curr = test_curr >=0; hyperpol_curr = test_curr < 0;
    s1 = scatter(max_test_pred_LN(depol_curr), max_test_truth(depol_curr), 100, 'filled', 'DisplayName', 'Depol');
    s1.MarkerFaceColor = "#00CD6C";
    s2 = scatter(max_test_pred_LN(hyperpol_curr), max_test_truth(hyperpol_curr), 100,'filled', 'DisplayName', 'Hyperpol');
    s2.MarkerFaceColor = "#AF58BA";
    
    r2 = corrcoef(max_test_truth, max_test_pred_LN);
    title( sprintf('r^2 = %f', r2(1,2) ^ 2));
    
    xlabel('Prediction from model');
    ylabel('Spikes (from data)');
    legend('Location', 'best');
    fontsize(15, 'points')
    %set table variables
    fprintf('Elapsed time = %d seconds\n', round(toc));
    %catch

    %end

end
