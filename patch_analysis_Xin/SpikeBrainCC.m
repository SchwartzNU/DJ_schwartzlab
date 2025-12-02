function R = SpikeBrainCC(data_group, params)

%this analysis requires a params struct that has filter_window_ms, 
%to input to a median filter to filter out spike and get the baseline membrane potential
%estimate_spike_width = params.spike_width_ms;
filter_window_ms = params.filter_window;

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;
R = sln_results.table_definition_from_template('SpikeBrainCC',N_datasets);

%type of CC we could process with this analysis
protocol_list = {'pulse', 'opto_pulse', 'optopulse_train'};

for i = 1:N_datasets
    %determine what protocol is that
    %prot_q = datasets_struct(i);
    protocol = fetch(sln_symphony.DatasetEpoch * sln_symphony.ExperimentEpochBlock & datasets_struct(i),...
       'protocol_name');
    prot_types = unique([protocol.epoch_block_id]);
    protname = unique({protocol.protocol_name});
    if (numel(prot_types)>1)
        error('More than 1 types of protocol is present in this dataset! please redo curating!/n');
    end
    tag_ar = strcmp(protname{1}, protocol_list);
    if (sum(tag_ar)==0)
        error('Protocol %s cannot be processed with this analysis!/n', protocol.protocol_name);        
    end

    pro_flag = find(tag_ar);
    %filling out basic info of the result struct
    R.file_name(i) = datasets_struct(i).file_name;
    R.source_id(i) = datasets_struct(i).source_id;
    R.dataset_name(i) = datasets_struct(i).dataset_name;
    R.stim_protocol_name(i) = protocol_list{pro_flag};
    
    %query spike data and the stimulus protocol of this dataset
    if pro_flag == 1
        prot_data = fetch(sln_symphony.ExperimentProtPulseV1bp...
            *sln_symphony.DatasetEpoch & datasets_struct(i), '*');
        R.stim_value(i) = prot_data(1).pulse_amplitude;
        R.stim_duration_ms(i) = prot_data(1).stim_time;

    elseif pro_flag == 2
        prot_data = fetch(sln_symphony.ExperimentProtOptoPulseV1bp...
             *sln_symphony.DatasetEpoch & datasets_struct(i), '*');
        R.stim_value(i) = prot_data(1).stim_time;
        R.stim_duration_ms(i) = prot_data(1).stim_time; %same thing for single pulse opto
    else
        prot_data = fetch(sln_symphony.ExperimentProtOptopulseTrainV1bp...
            *sln_symphony.DatasetEpoch & datasets_struct(i), '*');
        R.stim_value(i) =  1E3/(prot_data(1).downtime + prot_data(1).pulse_time);
        R.stim_duration_ms(i) = prot_data(1).stim_time;
    end

    %change when the data is recorded on left electrode
    datasets_struct(i).channel_name = 'Amp1';
    spikeTrace = fetch(sln_symphony.ExperimentChannel *sln_symphony.ExperimentEpochChannel ...
        * sln_symphony.DatasetEpoch*sln_symphony.SpikeTrainBrain &datasets_struct(i), '*');


    R.sample_rate(i) = spikeTrace(1).sample_rate;
     N_epochs = numel(spikeTrace);
     R.total_spike_count(i) = 0;
     R.total_elapsed_time_s(i) = N_epochs * (prot_data(1).pre_time + ...
         prot_data(1).stim_time + prot_data(1).tail_time)/1E3;
     spike_instim_sum = 0;
     spike_outstim_sum = 0;
     total_spike = 0;
     baseline_mp = [];
    
     fprintf('Processing of dataset %s, total epoch number: %d\n', datasets_struct(i).dataset_name, N_epochs);
     for j = 1:N_epochs
         %get the baseline membrane potential
         raw_trace = spikeTrace(j).raw_data;
          
         stim_start = prot_data(i).pre_time/1E3*R.sample_rate(i);
         stim_end = (prot_data(i).pre_time + prot_data(i).stim_time)/1E3*R.sample_rate(i);
         raw_trace(stim_start:stim_end+1) = [];
         
         filter_window_samp = filter_window_ms/1E3*R.sample_rate(i);
         filtered = medfilt1(raw_trace, filter_window_samp);
         baseline_mp(end+1) = mean(filtered, 'all');
         %adding up total spike 
         total_spike = total_spike+spikeTrace(j).spike_count;

         %select the spike that are within the stimulation period, for current injection epochs block especially
         if (spikeTrace(j).spike_count>0)
            spike_locs_ms = spikeTrace(j).spike_indices/R.sample_rate(i)*1E3;
            spike_instim_N = sum(spike_locs_ms>prot_data(i).pre_time & spike_locs_ms<(prot_data(i).pre_time + prot_data(i).stim_time));
            spike_instim_sum  = spike_instim_sum + spike_instim_N;
         else
             fprintf('No spike detected in epoch number %d\n', j);
         end

         %spike_outstim_sum = spike_outstim_sum + spikeTrace(j).spike_count-spike_instim_N;
     end

     %filling out the R struct
     R.total_spike_count(i) = total_spike;
     R.spike_frequency_all(i) = R.total_spike_count(i)/R.total_elapsed_time_s(i);
     R.mean_spike_count_in_stim(i) = spike_instim_sum/N_epochs;
     R.spike_count_within_stim(i) = spike_instim_sum;
     R.spike_count_out_stim(i) = total_spike-spike_instim_sum;
     R.baseline_mp_nostim(i) = {baseline_mp};
     R.mean_baseline_mp_nostim(i) = mean(baseline_mp, "all");

     fprintf('Processing finished! yay\n');

end


   
end

