function [result_struct]=FeatureExtract(result_table)
%% init
start_time = result_table.pre_time_ms * 10^-3 * result_table.sample_rate;
end_time = start_time + result_table.stim_time_ms * 10^-3 *result_table.sample_rate;
hyper_current_epoch = find(result_table.inj_current < 0);
depol_current_epoch = find(result_table.inj_current > 0);
hyper_current_level_pA = result_table.inj_current(hyper_current_epoch);
depol_current_level_pA = result_table.inj_current(depol_current_epoch);
hyper_Vm = result_table.example_traces(hyper_current_epoch,:);
hyper_Vm = hyper_Vm';
depol_Vm = result_table.example_traces(depol_current_epoch,:);
depol_Vm = depol_Vm';
time_in_s = linspace(0, size(hyper_Vm,1), size(hyper_Vm,1)) / result_table.sample_rate;

%%
stable_Vm = mean(hyper_Vm(start_time:end_time,:));
R_linear = fitlm(hyper_current_level_pA, stable_Vm');
resistance = struct();
resistance.R_MOhm = R_linear.Coefficients.Estimate('x1') * 1000; % V/I = mV/pA = 10^9(Giga) => Convert to 10^6 (Mega)Ohm
resistance.AdjustedRsqaured = R_linear.Rsquared.Adjusted;
if R_linear.Rsquared.Adjusted < 0.90
    warning('Resistance fit kinda sucky. Check if Ih went brrr')
end


% Calculate Tau (ms)
hyper_epoch_less_than_minus50 = find(hyper_current_level_pA > -50); % INJECTED CURRENT LESS HYPERPOLARIZING THAN -50

ft = fittype('a + b*exp(-x*c)', 'independent', 'x'); %One parameter exp fit with asymt to Vinf
tau_array = zeros(length(hyper_epoch_less_than_minus50),1);
Vinf_array = zeros(length(hyper_current_epoch), 1);
for i=1:length(hyper_epoch_less_than_minus50)
    f = fit([time_in_s(start_time:end_time)]', hyper_Vm(start_time:end_time,...
        hyper_epoch_less_than_minus50(i)), ft, 'StartPoint',[-60,10,30]);



    tau_array(i) =  f.c;


end


%Return tau struct
tau = struct();
tau.Tau_ms = mean(1./tau_array)*1000;
tau.SD_ms = std(1./tau_array)*1000;
tau.N = size(tau_array, 2);
if tau.SD_ms > 10
    warning('Tau SD too high')
end

%Return Capacitance
capacitance_pF = tau.Tau_ms / resistance.R_MOhm * 100;

%% Sag
min_Vm = min(hyper_Vm(:,hyper_current_level_pA <= -50), [], 1);
fit_sag_peak_vs_stable = fitlm(min_Vm, stable_Vm(hyper_current_level_pA <= -50));
sag_coeff = fit_sag_peak_vs_stable.Coefficients(2,1);

%% Does it spike spontaneously
spontaneous_peak_array = zeros(size(depol_current_level_pA,1), 1);


for i=1:size(depol_current_level_pA, 1)
    spontaneous_peak_array(i) = size(findpeaks(depol_Vm(1:start_time, i), ...
        "MinPeakProminence", 6, "MinPeakHeight", -10, "MinPeakDistance", result_table.sample_rate*1e-3),1);
end

spontaneous_spike = (mean(spontaneous_peak_array))/(start_time/result_table.sample_rate); %Hz

%% Find first spike
first_spike = [0 0 0]; %peak loc epoch
if spontaneous_spike ~= 0
    end_time_find = start_time;
    start_time_find = 1;
else 
    end_time_find = end_time;
    start_time_find = start_time;
end

i = 1;

while first_spike(2) == 0
    [pks, locs] = findpeaks(depol_Vm(start_time_find:end_time_find, i), ...
        'MinPeakProminence', 6, 'MinPeakHeight', -10, "MinPeakDistance", result_table.sample_rate*1e-3);

    try
        first_spike = [pks(1) locs(1) i];
    catch
        warning('No peak found')
    end
    i = i+1;

end

if spontaneous_spike == 0
    first_spike(2) = start_time_find + first_spike(2);

end
Vm_diff_1 = diff(depol_Vm(first_spike(2):(first_spike(2) + (10 * 1e-3 * result_table.sample_rate)), first_spike(3)),1); %take from 10ms
locations = find(Vm_diff_1 == 0);
trough = [0 0 0];
trough(2) = first_spike(2) + locations(1); % trough location;
trough(3) = first_spike(3); %trough epoch;
trough(1) = depol_Vm(trough(2), trough(3)); %trough level mV
start_time_for_threshold = max(1, (first_spike(2) - (5 * 1e-3 * result_table.sample_rate))); %take from -5ms or the start
Vm_diff_2 = diff(depol_Vm(start_time_for_threshold : first_spike(2), first_spike(3)), 1);
threshold_loc = find(Vm_diff_2 >= max(Vm_diff_2)*0.2,1);
V_threshold = depol_Vm(threshold_loc + 1, first_spike(3)); % + 1 bc diff lost one position
half_height = (first_spike(1) + trough(1)) / 2;
half_width_times = sum(depol_Vm(threshold_loc : trough(2), trough(3)) >= half_height) /result_table.sample_rate * 1e3;

%% spikes and ISIs during current injections

spike_numbers = zeros(length(depol_current_epoch), 1);
latency_to_first_spike = zeros(length(depol_current_epoch), 1);
adaptation_index = zeros(length(depol_current_epoch), 1);
ISI_cv = zeros(length(depol_current_epoch), 1);
blocked = zeros(length(depol_current_epoch), 1);

%figure; hold on;
for epoch=1:length(depol_current_epoch)
    
    %findpeaks(depol_Vm(start_time:end_time, epoch), ...
    %    'MinPeakProminence', 6, 'MinPeakHeight', -5, "MinPeakDistance", result_table.sample_rate*1e-3); 
    [spikes, locs] = findpeaks(depol_Vm(start_time:end_time, epoch), ...
        'MinPeakProminence', 6, 'MinPeakHeight', -10, "MinPeakDistance", result_table.sample_rate*1e-3); %peak separation at least 1 ms
    try
        latency_to_first_spike(epoch) = locs(1) *1e3 / result_table.sample_rate ;
        spike_numbers(epoch) = length(spikes);
        locs_move_1 = [0; locs(1:end-1)];
        ISIs = locs - locs_move_1; ISIs = ISIs(2:end);
        ISI_cv(epoch) = std(ISIs) / mean(ISIs);
        for j=1:(length(ISIs)-1)
           
            adaptation = (ISIs(j+1) - ISIs(j))/ (ISIs(j+1) + ISIs(j));
            adaptation_index(epoch) = adaptation_index(epoch) + adaptation;
            
        end
        adaptation_index(epoch) = adaptation_index(epoch) / (length(ISIs) - 1);
        if locs(end) < (end_time - start_time)/2
            blocked(epoch) = true;
        else
            blocked(epoch) = false;
        end
        
    catch
        latency_to_first_spike(epoch) =  (end_time - start_time)/ result_table.sample_rate*1e3;
        spike_numbers(epoch) = length(spikes);
    end
end

blocked_epoch = find(blocked == true, 1);
if isempty(blocked_epoch)
    blocked_current_level = NaN; % not blocked yet
else
    blocked_current_level = depol_current_level_pA(blocked_epoch(1));
end

%% Current level at which spike rate reach half-max on F-I curve

%spikerate_halfmax_current = interp1(spike_numbers, depol_current_level_pA, max(spike_numbers)/2);


%interpolation
interpolation_range = linspace(depol_current_level_pA(1), depol_current_level_pA(end), 10);
spike_numbers = interp1(depol_current_level_pA, spike_numbers,interpolation_range);
latency_to_first_spike = interp1(depol_current_level_pA, latency_to_first_spike, interpolation_range);
adaptation_index = interp1(depol_current_level_pA, adaptation_index, interpolation_range);
ISI_cv = interp1(depol_current_level_pA, ISI_cv, interpolation_range);

%% Return values
result_struct.resistance = resistance;
result_struct.tau = tau;
result_struct.capacitance_pF = capacitance_pF;
result_struct.depol_current_level = depol_current_level_pA;
result_struct.hyper_current_level = hyper_current_level_pA;
result_struct.resting_Vm = result_table.vrest;
result_struct.sag_coeff = sag_coeff;
result_struct.spontaneous_spike = spontaneous_spike;
result_struct.V_threshold = V_threshold;
result_struct.half_width_time = half_width_times;
result_struct.first_AP_peak = first_spike;
result_struct.first_AP_trough = trough;
result_struct.spike_number =spike_numbers;
result_struct.latency_to_first_spike = latency_to_first_spike;
result_struct.adaptaion_index = adaptation_index;
result_struct.ISI_cv = ISI_cv;
result_struct.block_current_level = blocked_current_level;
result_struct.max_slope = max(Vm_diff_2) * result_table.sample_rate / 1e3;  
%result_struct.spikerate_halfmax_current = spikerate_halfmax_current;
end