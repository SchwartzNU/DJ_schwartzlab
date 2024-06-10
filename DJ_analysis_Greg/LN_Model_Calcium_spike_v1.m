function R = LN_Model_Calcium_spike_v1(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;
%R = sln_results.table_definition_from_template('LN_Model_Calcium_spike_v1',N_datasets);
R = struct();
for d=1:N_datasets
    %try
    tic;
    rng(0)
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
        [~, locs] = findpeaks(raw_data(i,:),"MinPeakHeight", -10, 'MinPeakProminence', 6, 'MinPeakDistance', MIN_PEAK_DISTANCE);
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
    lp = LP_filter_32_6point4;
    trace_matrix = filtfilt(lp.sosMatrix, lp.ScaleValues, trace_matrix);
    max_calcium_signal = max(trace_matrix');
    %% resampling to 100Hz;
    spike_time_array = [0:size(raw_data,2)-1] / sample_rate ; % second
    cal_time_array = (0:time_points-1) / 1e3;
    spikes_data = resample(spikes_calcium_filtered', spike_time_array, 100);
    cal_data = resample(trace_matrix', cal_time_array, 100);
    %% split data
    number_of_trials = epochs_in_dataset(1).number_of_cycles;
    number_of_steps = epochs_in_dataset(1).number_of_steps;
    steps_to_scale = number_of_trials / 5;
    split_ratio = [2 , 2 , 1] .* steps_to_scale;
    idx_trials = randperm(number_of_trials);
    idx_trial_filter = idx_trials(1:split_ratio(1));
    idx_trial_nl = idx_trials(split_ratio(1) + 1 : split_ratio(1) + split_ratio(2));
    idx_trial_test = idx_trials(split_ratio(1) + split_ratio(2) + 1 : end);
    train_idx_filter = reshape(idx_trial_filter' * [1:number_of_steps], 1, []);
    train_idx_nl = reshape(idx_trial_nl' * [1:number_of_steps], 1, []);
    test_idx = reshape(idx_trial_test'* [1:number_of_steps], 1, []);
    spike_training = spikes_data(:,train_idx_filter)';
    spike_test = spikes_data(:, test_idx)';
    spike_training_nl = spikes_data(:, train_idx_nl)';
    cal_training = cal_data(:,train_idx_filter)';
    cal_test = cal_data(:, test_idx)';
    cal_training_nl = cal_data(:, train_idx_nl)';
    %% LN
    filt_f = zeros(size(train_idx_filter,2), size(cal_training, 2));
    for i=1:size(cal_training,1)
        cal_training_temp = cal_training(i,:);
        spike_training_temp = spike_training(i,:);
        L = length(cal_training_temp);
        freq = 100*(0:(L/2))/L;
        filt_f(i,:) = (fft(spike_training_temp) .* conj(fft(cal_training_temp))) ./ (fft(cal_training_temp) .* conj(fft(cal_training_temp)));
    end
    filt_t = real(ifft(mean(filt_f,1)));
    L = size(filt_t,2);
    filt_t = [filt_t, filt_t];
    filt_t = filt_t(L/2 : (L/2 + L-1)); %FINAL FILTER PLOT THIS
    filt_t = filt_t  / abs(max(filt_t));

    nl_train_pred_array = nan(size(spike_training_nl));
    for i = 1: size(train_idx_nl,2)
        cal_test_temp = cal_training_nl(i,:); %- mean(cal_training_nl(i,:)));
        pred = conv(cal_test_temp, filt_t,'same');
        nl_train_pred_array(i, :) = pred;

    end

    % sort in to bins
    nl_train_pred_lookup = sort(reshape(nl_train_pred_array', [], 1));
    nl_train_truth_lookup = sort(reshape(spike_training_nl', [], 1));
    Nbins = 100;
    %NL_bins = prctile(a, 0:Nbins);
    step_size = floor(size(nl_train_pred_lookup,1) / Nbins);
    NL_x = zeros(1, Nbins);
    NL_y = zeros(1, Nbins);
    for i=1:Nbins
        %ind = find(a>=NL_bins(i) & a<=NL_bins(i+1));
        ind = [1:step_size] + (i-1) * step_size;
        if i == Nbins
            ind = [ind(1) : size(nl_train_pred_lookup,1)];
        end
        NL_x(i) = mean(nl_train_pred_lookup(ind));
        NL_y(i) = mean(nl_train_truth_lookup(ind));
    end
    %spline_fit = fit(nl_train_pred_lookup, nl_train_truth_lookup, 'smoothingspline', 'SmoothingParam', 0.95);
    spline_fit = csaps(nl_train_pred_lookup, nl_train_truth_lookup, 0.99);
    spline_fit_extrap = fnxtr(spline_fit, 1);
    %figure;
    %fnplt(spline_fit_extrap);
    pred_array = nan(size(spike_test));
    pred_array_spline = nan(size(spike_test));
    for i = 1:size(test_idx,2)
        cal_test_temp = cal_test(i,:);% - mean(cal_test(i,:)));
        pred = conv(cal_test_temp, filt_t, 'same');
        %pred = pred(1:L)
        pred_array(i, :) = interp1(NL_x, NL_y, pred(1:size(cal_test_temp,2)), 'linear', 'extrap');
        pred_array_spline(i,:) = fnval(spline_fit_extrap, pred); %feval(spline_fit, pred);
    end
    %plot parts -comment this out later
    % filter shape
    f1 = figure('Name', 'Filter and non-linear');
    subplot(1,2,1);
    plot(filt_t, 'LineWidth', 3);
    xlim([0, size(filt_t, 2)]);
    set(gcf, 'Color', 'w');
    % non linear part
    subplot(1,2,2);
    hold on;
    scatter(nl_train_pred_lookup, nl_train_truth_lookup, 50, 'HandleVisibility','off');
    % line_interp_x = [0 : max(nl_train_pred_lookup)];
    % line_interp_y = interp1(NL_x, NL_y, line_interp_x, 'linear', 'extrap');
    % plot(line_interp_x, line_interp_y, 'LineWidth', 4, 'DisplayName', 'Interpolated non linearity');
    points = fnplt(spline_fit_extrap);
    %plot(points(1,:), points(2,:), 'LineWidth', 3, 'DisplayName', 'Spline fit');
    fnplt(spline_fit_extrap, 3);
    legend('Location', 'northwest')
    xlabel('Predicted \Delta of spike');
    ylabel('True \Delta of spikes');
    fontsize(15, 'points');
    f1.Position(3:4) = [945, 420];
    % plot overlaping traces
    f2 = figure('Name', 'Testing');
    truth = reshape(spike_test', [],1);
    predicted = reshape(pred_array', [], 1);
    predicted_spline = reshape(pred_array_spline', [],1);
    ax1 = subplot(2,1,1);
    plot(truth, 'LineWidth', 3);
    ax2 = subplot(2,1,2);
    %plot(predicted, 'LineWidth', 3);
    plot(predicted_spline, 'LineWidth',3);
    linkaxes([ax1, ax2], 'xy');
    pearson_coeff = corrcoef(truth, predicted_spline);
    %set table variables
    R(d).filter = filt_t;
    R(d).spline_points_x = points(1,:);
    R(d).spline_points_y = points(2,:);
    R(d).truth_test = truth;
    R(d).predicted_test = predicted_spline;
    R(d).corr_eff = pearson_coeff(1,2);
    R(d).cal_test = cal_test;
    fprintf('Elapsed time = %d seconds\n', round(toc));
    set(f2, 'Color', 'w');
    %catch
    %end
end
