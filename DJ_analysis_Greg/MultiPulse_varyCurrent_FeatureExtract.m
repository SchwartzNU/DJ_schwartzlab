function R = MultiPulse_varyCurrent_FeatureExtract(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;
R = sln_results.table_definition_from_template('MultiPulse_varyCurrent_FeatureExtract',N_datasets);
for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);
    
    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.MultiPulseParams & ...
        datasets_struct(d),'*');
    N_epochs = length(epochs_in_dataset);
    
    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end
    
    %parameters to save for the whole dataset
    sample_rate = epochs_in_dataset(1).sample_rate;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_1_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
    stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
    tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
    total_samples = pre_samples + stim_samples + tail_samples;
    ss_samples = 50E-3 * sample_rate;
    
    all_currents = [epochs_in_dataset.pulse_1_curr];
    
    currents  = sort(unique(all_currents));
    N_currents = length(currents);
    
    N_epochs_per_current = zeros(N_currents,1);
    vmax = zeros(N_currents,1);
    vmin = zeros(N_currents,1);
    vmax_rebound = zeros(N_currents,1);
    vmin_rebound = zeros(N_currents,1);
    vsteady= zeros(N_currents,1);
    tmax = zeros(N_currents,1);
    tmin = zeros(N_currents,1);
    tmax_rebound = zeros(N_currents,1);
    tmin_rebound = zeros(N_currents,1);
    vrest_vector = zeros(N_currents,1);
    mean_traces = zeros(N_currents, total_samples);
    example_traces = zeros(N_currents, total_samples);
    countstbl = countlabels(all_currents);
    number_of_trials = max(countstbl.Count);
    if sum(countstbl.Count ~= number_of_trials) > 0 || number_of_trials  ~= epochs_in_dataset(1).number_of_cycles
        warning('Numbers of epochs between trials are not the same')
        number_of_trials = min(countstbl.Count);
    end % maximize the number of complete trials for analysis
    
    all_traces = cell(N_currents, number_of_trials);
    % cell array of current (row) x trial (columns)
    
    for s=1:N_currents
        ind = find(all_currents == currents(s));
        N_epochs_per_current(s) = length(ind);
        trace = mean(reshape([epochs_in_dataset(ind).raw_data], [], length(ind)), 2)';
        mean_traces(s,:) = trace;
        example_traces(s,:) = epochs_in_dataset(ind(1)).raw_data;
        
        for j = 1:number_of_trials
            
            all_traces{s, j} = [epochs_in_dataset(ind(j)).raw_data];
        end
        
        vrest_vector(s) = mean(trace(1:pre_samples));
        
        vsteady(s) = mean(trace(pre_samples+stim_samples-ss_samples:pre_samples+stim_samples));
        if currents(s)>0
            [vmax(s), t] = max(trace(pre_samples+1:pre_samples+stim_samples));
            vmax(s) = vmax(s) - vsteady(s); %overshoot
            tmax(s) = 1E3 * t / sample_rate;
        else
            [vmin(s), t] = min(trace(pre_samples+1:pre_samples+stim_samples) - vrest_vector(s));
            tmin(s) = 1E3 * t / sample_rate;
        end
        
        [vmax_rebound(s), t] = max(trace(pre_samples+stim_samples+1:end) - vrest_vector(s));
        tmax_rebound(s) = 1E3 * t / sample_rate;
        [vmin_rebound(s), t] = min(trace(pre_samples+stim_samples+1:end) - vrest_vector(s));
        tmin_rebound(s) = 1E3 * t / sample_rate;
        
        
        
    end
    
    %% Feature Extraction Part
    %% Init
    start_time = pre_stim_tail.pre_time * 10^-3 * sample_rate;
    end_time = start_time + pre_stim_tail.stim_time * 10^-3 * sample_rate;
    hyper_current_epoch = find(currents' < 0);
    depol_current_epoch = find(currents' > 0);
    hyper_current_level_pA = currents(hyper_current_epoch);
    hyper_current_level_pA = hyper_current_level_pA';
    depol_current_level_pA = currents(depol_current_epoch);
    depol_current_level_pA = depol_current_level_pA';
    MIN_PEAK_HEIGHT = -10; %mV, change to 0 when access resistance is standardized and all peaked is ensured to overshoot 0.
    MIN_PEAK_PROMINENCE = 6; %works well for ganglions. Decrease to find smaller peaks.
    MIN_PEAK_DISTANCE = sample_rate*1e-3; %peak separation of at least 1ms;
    THRESHOLD_FIND_WINDOWS =  5; % ms before the spike to find the threshold of first AP
    AHP_FIND_WINDOWS = 10; % ms after depol current injection to find AHP peak (anti-peak)
    
    % return arrays most are in the shape of (number of trials, 1)
    resistance_array_MOhm = nan(number_of_trials, 1);
    resistance_Adjusted_RSquare = nan(number_of_trials, 1);
    tau_array_ms = nan(number_of_trials,1);
    capacitance_array_pF = nan(number_of_trials,1);
    sag_array = nan(number_of_trials, 1);
    spontaneous_firing_rate_Hz = nan(number_of_trials, 1);
    V_threshold_array_mV = nan(number_of_trials, 1);
    half_width_time_array_ms = nan(number_of_trials, 1);
    first_AP_peak_amplitude_mV = nan(number_of_trials, 1);
    first_AP_peak_location_ms = nan(number_of_trials, 1);
    first_AP_trough_amplitude_mV = nan(number_of_trials, 1);
    first_AP_trough_location_ms = nan(number_of_trials, 1);
    max_number_of_spikes = nan(number_of_trials, 1);
    current_where_max_spikes = nan(number_of_trials, 1);
    max_latency_of_spike = nan(number_of_trials, 1);
    max_adaptation_index = nan(number_of_trials, 1);
    max_ISI_CV = nan(number_of_trials, 1);
    first_current_level_to_block = nan(number_of_trials, 1);
    max_slope_array_mV = nan(number_of_trials, 1);
    half_max_spike_number = nan(number_of_trials,1);
    half_max_spike_current = nan(number_of_trials, 1);
    Nspike_max_vs_last_epoch_ratio = nan(number_of_trials, 1);
    max_AHP_after_depol_injection = nan(number_of_trials, 1);
    max_63_percent_decay_time = nan(number_of_trials, 1);
    min_63_percent_decay_time = nan(number_of_trials, 1);
    spontenous_spike_amplitude_cv = nan(number_of_trials, 1);
    %start of the FE loop
    for trial = 1:number_of_trials
        %get voltage trace into matrix of time x current
        hyper_Vm = cell2mat(all_traces(hyper_current_epoch, trial));
        hyper_Vm = hyper_Vm';
        depol_Vm = cell2mat(all_traces(depol_current_epoch, trial));
        depol_Vm = depol_Vm';
        time_in_s = (0:size(hyper_Vm,1) - 1) / sample_rate;
        
        
        %resistance fit
        stable_Vm = mean(hyper_Vm(start_time:end_time,:));
        R_linear = fitlm(hyper_current_level_pA, stable_Vm');
        
        resistance_array_MOhm(trial) = R_linear.Coefficients.Estimate('x1') * 1000; % V/I = mV/pA = 10^9(Giga) => Convert to 10^6 (Mega)Ohm
        resistance_Adjusted_RSquare(trial) = R_linear.Rsquared.Adjusted;
        if R_linear.Rsquared.Adjusted < 0.90
            warning('Resistance fit is bad. Check if Ih kicked in!')
        end
        
        % Calculate Tau (ms)
        hyper_epoch_less_than_minus50 = find(hyper_current_level_pA > -50); % INJECTED CURRENT LESS HYPERPOLARIZING THAN -50
        
        ft = fittype('a + b*exp(-x*c)', 'independent', 'x'); %One parameter exp fit with asymt to Vinf
        tau_array = zeros(length(hyper_epoch_less_than_minus50),1);
        
        for i=1:length(hyper_epoch_less_than_minus50)
            f = fit([time_in_s(start_time:end_time)]', hyper_Vm(start_time:end_time,...
                hyper_epoch_less_than_minus50(i)), ft, 'StartPoint',[-60,10,30]);
            tau_array(i) =  f.c;
        end
        
        
        %Return tau
        
        tau_array_ms(trial) = mean(1./tau_array)*1000;
        if std(1./tau_array)*1000 > 10
            warning('Tau SD too high')
        end
        
        %Return Capacitance
        capacitance_array_pF(trial) = tau_array_ms(trial) / resistance_array_MOhm(trial) * 100;
        
        %% Sag
        min_Vm = min(hyper_Vm(:,hyper_current_level_pA <= -50), [], 1);
        fit_sag_peak_vs_stable = fitlm(min_Vm, stable_Vm(hyper_current_level_pA <= -50));
        sag_array(trial) = table2array(fit_sag_peak_vs_stable.Coefficients(2,1));
        
        %% Does it spike spontaneously
        spontaneous_peak_array = zeros(size(depol_current_level_pA,1), 1);
        spike_amplitudes = [];
        
        for i=1:size(depol_current_level_pA, 1)
            spontaneous_spikes = findpeaks(depol_Vm(1:start_time, i), ...
                "MinPeakProminence", MIN_PEAK_PROMINENCE, "MinPeakHeight", MIN_PEAK_HEIGHT, "MinPeakDistance", MIN_PEAK_DISTANCE);
            spontaneous_peak_array(i) = size(spontaneous_spikes,1);
            spike_amplitudes = cat(1, spike_amplitudes, spontaneous_spikes);
        end
        
        spontaneous_firing_rate_Hz(trial) = (mean(spontaneous_peak_array))/(start_time/sample_rate); %Hz
        spontenous_spike_amplitude_cv(trial) = std(spike_amplitudes) ./ mean(spike_amplitudes);
        
        
        %% Find first spike
        first_spike = [0 0 0]; %peak loc epoch
        trough = [0 0 0]; %mV ms epoch#
        if spontaneous_firing_rate_Hz(trial) ~= 0
            end_time_find = start_time;
            start_time_find = 1;
        else
            end_time_find = end_time;
            start_time_find = start_time;
        end
        
        i = 1;
        size(depol_Vm,1)
        while first_spike(2) == 0 && i <= size(depol_Vm, 1)
            [pks, locs] = findpeaks(depol_Vm(start_time_find:end_time_find, i), ...
                'MinPeakProminence', MIN_PEAK_PROMINENCE, 'MinPeakHeight', MIN_PEAK_HEIGHT, ...
                "MinPeakDistance", MIN_PEAK_DISTANCE);
            try
                first_spike = [pks(1) locs(1) i];
            catch
                warning('No peak found')
            end

            i = i+1;
            
        end
        if spontaneous_firing_rate_Hz(trial) == 0
            first_spike(2) = start_time_find + first_spike(2);
        end
        
        try
        Vm_diff_1 = diff(depol_Vm(first_spike(2):(first_spike(2) + (10 * 1e-3 * sample_rate)), first_spike(3)),1); %take from 10ms
        locations = find(Vm_diff_1 == 0);
        
        trough(2) = first_spike(2) + locations(1); % trough location;
        trough(3) = first_spike(3); %trough epoch;
        trough(1) = depol_Vm(trough(2), trough(3)); %trough level mV
        start_time_for_threshold = max(1, (first_spike(2) - (THRESHOLD_FIND_WINDOWS * 1e-3 * sample_rate)));
        Vm_diff_2 = diff(depol_Vm(start_time_for_threshold : first_spike(2), first_spike(3)), 1);
        threshold_loc = find(Vm_diff_2 >= max(Vm_diff_2)*0.2,1);
        V_threshold_array_mV(trial) = depol_Vm(threshold_loc + 1, first_spike(3)); % + 1 bc diff lost one position
        half_height = (first_spike(1) + trough(1)) / 2;
        half_width_time_array_ms(trial) = sum(depol_Vm(threshold_loc : trough(2), trough(3)) >= half_height) /sample_rate * 1e3;
        catch
            pks = 0;
            locs = 0;
        end
        first_AP_peak_amplitude_mV(trial) = first_spike(1);
        first_AP_peak_location_ms(trial) = first_spike(2);
        first_AP_trough_amplitude_mV(trial) = trough(1);
        first_AP_trough_location_ms(trial) = trough(2);
        
        
        %% spikes and ISIs during current injections
        
        spike_numbers = zeros(length(depol_current_epoch), 1);
        latency_to_first_spike = zeros(length(depol_current_epoch), 1);
        adaptation_index = zeros(length(depol_current_epoch), 1);
        ISI_cv = zeros(length(depol_current_epoch), 1);
        blocked = zeros(length(depol_current_epoch), 1);
        decay_to_63_percent = zeros(length(depol_current_epoch),1);
        
        for epoch=1:length(depol_current_epoch)
            [spikes, locs] = findpeaks(depol_Vm(start_time:end_time, epoch), ...
                'MinPeakProminence', 6, 'MinPeakHeight', -10, "MinPeakDistance", sample_rate*1e-3); %peak separation at least 1 ms
            try
                latency_to_first_spike(epoch) = locs(1) *1e3 / sample_rate ;
                spike_numbers(epoch) = length(spikes);
                locs_move_1 = [0; locs(1:end-1)];
                ISIs = locs - locs_move_1; ISIs = ISIs(2:end);
                ISI_cv(epoch) = std(ISIs) / mean(ISIs);
                for j=1:(length(ISIs)-1)
                    
                    adaptation = (ISIs(j+1) - ISIs(j))/ (ISIs(j+1) + ISIs(j));
                    adaptation_index(epoch) = adaptation_index(epoch) + adaptation;
                    
                end
                adaptation_index(epoch) = adaptation_index(epoch) / (length(ISIs) - 1);
                if locs(end) < (end_time - start_time)/2 % if spike train stops before half of the stim time
                    blocked(epoch) = true;
                else
                    blocked(epoch) = false;
                end
                
                %decay 36%
                
                spike_63_loc = find(abs(spikes) < abs((spikes(1) * 0.63)), 1);
                
                if ~isempty(spike_63_loc)
                    
                    decay_to_63_percent(epoch) = locs(spike_63_loc) / sample_rate * 1e3; %ms
                else
                    decay_to_63_percent(epoch) = NaN; %(end_time - start_time)/ sample_rate*1e3;
                end
            catch
                latency_to_first_spike(epoch) =  (end_time - start_time)/ sample_rate*1e3;
                spike_numbers(epoch) = length(spikes);
                decay_to_63_percent(epoch) = NaN; %(end_time - start_time)/ sample_rate*1e3;
            end
        end
        
        blocked_epoch = find(blocked == true, 1);
        if isempty(blocked_epoch)
            blocked_current_level = 999; % not blocked yet
        else
            blocked_current_level = depol_current_level_pA(blocked_epoch(1));
        end
        
        [max_number_of_spikes(trial), epoch_max_loc] = max(spike_numbers);
        current_where_max_spikes(trial) = depol_current_level_pA(epoch_max_loc);
        max_latency_of_spike(trial) = max(latency_to_first_spike);
        max_adaptation_index(trial) = max(adaptation_index);
        max_ISI_CV(trial) = max(ISI_cv);
        first_current_level_to_block(trial) = blocked_current_level;
        max_slope_array_mV(trial) = max(Vm_diff_2) * sample_rate / 1e3;
        
        spike_number_at_0_pA = spontaneous_firing_rate_Hz(trial) * pre_stim_tail.stim_time / 1E3;
        
        horizontal_line_half_max_x = [0:1:depol_current_level_pA(epoch_max_loc)];
        horizontal_line_half_max_y = repelem((max_number_of_spikes(trial) + spike_number_at_0_pA)/2, length(horizontal_line_half_max_x));
        
        [xi yi] = polyxpoly([0;depol_current_level_pA(1: epoch_max_loc)], [spike_number_at_0_pA; spike_numbers(1:epoch_max_loc)], ...
            horizontal_line_half_max_x, horizontal_line_half_max_y);
        
        if ~isempty(xi) || ~isempty(yi)
            
            half_max_spike_number(trial) = yi(1);
            half_max_spike_current(trial) = xi(1);
        else
            half_max_spike_current(trial) = NaN;
            half_max_spike_number(trial) = NaN;
        end
        
        Nspike_max_vs_last_epoch_ratio(trial) = max_number_of_spikes(trial) / spike_numbers(end);
        max_AHP_after_depol_injection(trial) = min(min(depol_Vm(end_time : (end_time + AHP_FIND_WINDOWS * sample_rate / 1e3),:)));
        max_63_percent_decay_time(trial) = max(decay_to_63_percent);
        min_63_percent_decay_time(trial) = min(decay_to_63_percent);
    end % Feature Extraction end. Don't paste things outside of this loop.
    
    
    
    %% Returning
    vrest = mean(vrest_vector);
    %set table variables
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.inj_current{d} = currents';
    R.pre_time_ms(d) = pre_stim_tail.pre_time;
    R.stim_time_ms(d) = pre_stim_tail.stim_time;
    R.n_epochs_per_current{d} = N_epochs_per_current;
    R.vrest(d) = vrest;
    R.vsteady{d} = vsteady;
    R.vmax{d} = vmax;
    R.vmax_norm{d} = vmax ./ max(vmax);
    R.vmin{d} = vmin;
    R.vmax_rebound{d} = vmax_rebound;
    R.vmin_rebound{d} = vmin_rebound;
    R.tmax{d} = tmax;
    R.tmin{d} = tmin;
    R.tmax_rebound{d} = tmax_rebound;
    R.tmin_rebound{d} = tmin_rebound;
    R.mean_traces{d} = mean_traces;
    R.example_traces{d} = example_traces;
    R.sample_rate(d) = sample_rate;
    % Feature parts. Everything is returned into a cell of n trials 
    R.resistance{d} =resistance_array_MOhm ;
    R.resistance_rsquared{d} =resistance_Adjusted_RSquare ;
    R.tau{d} =tau_array_ms ;
    R.capacitance{d} =capacitance_array_pF;
    R.sag{d} =sag_array ;
    R.spontaneous_firing_rate{d} =spontaneous_firing_rate_Hz ;
    R.v_threshold{d} =V_threshold_array_mV ;
    R.half_width_time{d} =half_width_time_array_ms ;
    R.first_ap_peak_amplitude{d} =first_AP_peak_amplitude_mV ;
    R.first_ap_peak_time{d} =first_AP_peak_location_ms ;
    R.first_ap_trough_amplitude{d} =first_AP_trough_amplitude_mV ;
    R.first_ap_trough_time{d} =first_AP_trough_location_ms ;
    R.max_number_of_spike{d} =max_number_of_spikes ;
    R.current_max_number_of_spike{d} =current_where_max_spikes ;
    R.max_latency_of_spike{d} =max_latency_of_spike ;
    R.max_adaptation_index{d} =max_adaptation_index ;
    R.max_isi_cv{d} =max_ISI_CV ;
    R.first_current_level_to_block{d} =first_current_level_to_block;
    R.max_slope{d} =max_slope_array_mV ;
    R.half_max_spike_number{d} =half_max_spike_number ;
    R.half_max_spike_current{d} =half_max_spike_current ;
    R.nspike_ratio{d} =Nspike_max_vs_last_epoch_ratio ;
    R.max_ahp_after_depol_injection{d} =max_AHP_after_depol_injection ;
    R.max_63_percent_decay_time{d} =max_63_percent_decay_time ;
    R.min_63_percent_decay_time{d} =min_63_percent_decay_time ;
    R.spontenous_spike_amplitude_cv{d} =spontenous_spike_amplitude_cv;
    
    fprintf('Elapsed time = %d seconds\n', round(toc));
    
end