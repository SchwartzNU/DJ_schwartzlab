%{
# CC epoch basics
-> sln_symphony.ExperimentEpochChannel
---
analysis_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
pre_spike_rate = NULL : float #spikes per sec
stim_spike_rate = NULL : float #spikes per sec
post_spike_rate = NULL : float #spikes per sec
isolated_spike_shape = NULL : longblob #waveform of most isolated spike in this epoch
resting_potential : float #mV, after some median filtering to remove spikes
pre_time_variance : float #mV^2
spike_thres = NULL : float #mV, for most isolated spike
spike_height = NULL : float #mV, total height
spike_max = NULL : float #mV, max voltage reached 
spike_fwhm = NULL : float #ms, full width at half max
spike_rising_slope = NULL : float #V/s
spike_falling_slope = NULL : float #V/s
spike_ahp = NULL : float #mV below threshold
max_voltage : float #raw max in this epoch
min_voltage : float #raw min in this epoch
input_resistance = NULL : float #mOhms, only if this is a pulse or multi-pulse epoch with mid-range hyperpolarizing current
%}
classdef CCEpochStats < dj.Computed
    properties
        keySource = sln_symphony.ExperimentEpochChannel & ...
            (sln_symphony.ExperimentEpochBlock * ...
            sln_symphony.ExperimentElectrode & ...
            'amp_mode="Whole cell" or amp_mode LIKE "Perforated%"' & ...
            'recording_mode="Voltage clamp"'); 
    end

    methods(Access=protected)
        function makeTuples(self, key)
            try

                thisEpoch = sln_symphony.ExperimentEpochBlock * ...
                    sln_symphony.ExperimentEpochGroup * ...
                    sln_symphony.ExperimentEpochChannel * ...
                    sln_symphony.ExperimentChannel & key;

                prot_name = fetch1(thisEpoch,'protocol_name');
                thisEpoch =  thisEpoch * ...
                    aka.BlockParams(sqlProtName2ProtName(prot_name)) * ...
                    aka.EpochParams(sqlProtName2ProtName(prot_name));

                thisEpoch_struct = fetch(thisEpoch,'*');
                spike_times = [];
                sp = sln_symphony.SpikeTrain & thisEpoch;
                if sp.exists
                    spike_times = fetch1(sp,'spike_indices');
                end
                spike_times = double(spike_times) ./ thisEpoch_struct.sample_rate; %now in seconds

                %spike counts
                pre_spikes = spike_times(spike_times <= thisEpoch_struct.pre_time/1E3);
                n_pre_spikes = length(pre_spikes);
                key.pre_spike_rate = n_pre_spikes ./ (thisEpoch_struct.pre_time/1E3);
                stim_time = [];
                if isfield(thisEpoch_struct, 'stim_1_time')
                    stim_time = thisEpoch_struct.stim_1_time;
                elseif isfield(thisEpoch_struct, 'stim_time')
                    stim_time = thisEpoch_struct.stim_time;
                end
                if ~isempty(stim_time)
                    stim_spikes = spike_times(spike_times > thisEpoch_struct.pre_time/1E3 & ...
                        spike_times <= thisEpoch_struct.pre_time/1E3 + stim_time/1E3);
                    n_stim_spikes = length(stim_spikes);
                    key.stim_spike_rate = n_stim_spikes ./ (stim_time/1E3);
                    if isfield(thisEpoch_struct, 'tail_time')
                        post_spikes = spike_times(spike_times > thisEpoch_struct.pre_time/1E3 + stim_time/1E3);
                        n_post_spikes = length(post_spikes);
                        key.post_spike_rate = n_post_spikes ./ (thisEpoch_struct.tail_time/1E3);
                    end
                end

                ms_for_med_filter = 10;
                samples_for_med_filter = round(thisEpoch_struct.sample_rate*ms_for_med_filter/1E3);
                pre_trace = thisEpoch_struct.raw_data(1:round((thisEpoch_struct.pre_time/1E3).*thisEpoch_struct.sample_rate));
                pre_trace_filtered = movmedian(pre_trace,samples_for_med_filter);
                key.resting_potential = mean(pre_trace_filtered);
                key.pre_time_variance = var(pre_trace);
                key.max_voltage = max(thisEpoch_struct.raw_data);
                key.min_voltage = min(thisEpoch_struct.raw_data);

                %spike waveform stuff
                if ~isempty(spike_times)
                    ms_for_spike_waveform = 10;
                    samples_for_spike_waveform = round(thisEpoch_struct.sample_rate*ms_for_spike_waveform/1E3);

                    if ~isempty(pre_spikes)
                        isolated_spike_sample = round(thisEpoch_struct.sample_rate*pre_spikes(1));
                        if isolated_spike_sample <= samples_for_spike_waveform/2
                            isolated_spike_sample = round(thisEpoch_struct.sample_rate*pre_spikes(2));
                        end
                    elseif ~isempty(post_spikes)
                        post_spike_time = diff([thisEpoch_struct.pre_time/1E3 + stim_time/1E3, spike_times]);
                        [~, ind] = min(post_spike_time);
                        isolated_spike_sample = round(thisEpoch_struct.sample_rate*post_spikes(ind));
                    else
                        isolated_spike_sample = round(thisEpoch_struct.sample_rate*stim_spikes(1));
                    end


                    
                    waveform = thisEpoch_struct.raw_data(round(isolated_spike_sample-samples_for_spike_waveform/2):...
                        round(isolated_spike_sample+samples_for_spike_waveform/2));

                    middle_ind = round(samples_for_spike_waveform/2+1);

                    %plot(waveform);

                    key.isolated_spike_shape = waveform;
                    key.spike_max = waveform(middle_ind);
                    first_deriv = diff(waveform);
                    second_deriv = diff(first_deriv);
                    upstroke = waveform(1:middle_ind);
                    downstroke = waveform(middle_ind+1:end);
                    first_deriv_up = diff(upstroke);
                    ms_for_slope_search = 3;
                    samples_for_slope_search = round(thisEpoch_struct.sample_rate*ms_for_slope_search/1E3);
                    [rising_slope_val, rising_slope_ind] = max(first_deriv_up(end-samples_for_slope_search:end));
                    rising_slope_ind = rising_slope_ind+length(first_deriv_up)-samples_for_slope_search;
                    key.spike_rising_slope = 1E-3*rising_slope_val.*thisEpoch_struct.sample_rate;
                    first_deriv_down = diff(downstroke);
                    key.spike_falling_slope = 1E-3*min(first_deriv_down).*thisEpoch_struct.sample_rate;

                    ms_for_thres_search = 3;
                    samples_for_thres_search = round(thisEpoch_struct.sample_rate*ms_for_thres_search/1E3);

                    thres_search_part = rising_slope_ind - samples_for_thres_search:rising_slope_ind;
                    %find where second derivative crosses 3 std
                    thres_val = 3*std(second_deriv(thres_search_part));
                    thres_ind = getThresCross(second_deriv(thres_search_part),thres_val,1);
                    if ~isempty(thres_ind)
                        thres_ind = thres_ind(1);
                    else
                        thres_val = 2*std(second_deriv(thres_search_part));
                        thres_ind = getThresCross(second_deriv(thres_search_part),thres_val,1);
                        if ~isempty(thres_ind)
                            thres_ind = thres_ind(1);
                        end
                    end
                    if isempty(thres_ind)
                        error('Spike threshold detection error');
                    end
                    thres_ind = rising_slope_ind-samples_for_thres_search+thres_ind-2; %-2 is for second deriv.
                    key.spike_thres = waveform(thres_ind);
                    key.spike_height = key.spike_max - key.spike_thres;
                    key.spike_ahp = -(min(downstroke) - min(upstroke));
                    half_max_val = key.spike_thres + key.spike_height/2;
                    up_ind = getThresCross(upstroke,half_max_val,1);
                    up_ind = up_ind(end);
                    down_ind = getThresCross(downstroke,half_max_val,-1);
                    if ~isempty(down_ind)
                        down_ind = down_ind(1);
                        key.spike_fwhm = ((middle_ind-up_ind) + down_ind)./thisEpoch_struct.sample_rate.*1E3; %ms
                    end
                end

                self.insert(key);

            catch ME
                disp(ME.message);
                rethrow(ME)
            end
        end
    end

    methods
        function err = errors(self)
            err = self.keySource - sln_results.CCEpochStats;
        end
    end
end