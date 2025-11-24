function R = PscOptoStats(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

%if_pulse_train = params.if_pulse_train;

R = sln_results.table_definition_from_template('PscOptoStats',N_datasets);
fprintf('Processing %s _source_id%d:%s for PSC stats......\n', datasets_struct(1).file_name, datasets_struct(1).source_id);

for d = 1:N_datasets
    datasets_struct(d).channel_name = 'Amp1'; %change this if the recording is from channel 2

    %try fetching single and multi opto pulse setting and PSC detections for the datasets...
    single_pulse_in_dataset = fetch(sln_symphony.DatasetEpoch * sln_results.EpochPostsynapticCurrent...
        *aka.EpochParams('OptoPulse') * aka.BlockParams('OptoPulse')...
        & datasets_struct(d), '*');
    N_epochs_sg = length(single_pulse_in_dataset);

    multi_pulse_in_dataset = fetch(sln_symphony.DatasetEpoch *sln_results.EpochPostsynapticCurrent...
        *aka.EpochParams('OptopulseTrain') * aka.BlockParams('OptopulseTrain')... %no idea why p is lower case but here it is
        & datasets_struct(d), '*');
    N_epochs_mul = length(multi_pulse_in_dataset);

    %the dataset can only be EITHER signle pulse OR multi pulse, but not both. And has to have one of them
    if (~xor(N_epochs_sg, N_epochs_mul))
        if (N_epochs_sg == 0)
            error('No epochs of opto pulse or pulse train found in dataset: %s. Analysis terminating..', datasets_struct(d).dataset_name);
        else
            error('Found both single and multi opto pulse epochs in the dataset %s, please redo.', datasets_struct(d).dataset_name);
        end
    end

    %deal single and multiple pulse differently
    flag_single = (N_epochs_sg~=0);
    %copy basic info
    R.file_name(d) = datasets_struct(d).file_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.dataset_name(d) = datasets_struct(d).dataset_name;

    if (flag_single)
        peak_amps = [];
        psc_total = 0;
        start_latency = [];
        risetime = [];
        R.if_multi_pulse(d) = false;
        
        for j = 1:N_epochs_sg
            %skipping no psc trial. Otherwise nan will pollute the dataset
            if (single_pulse_in_dataset(j).psc_total~=0)
                psc_total  = psc_total+single_pulse_in_dataset(j).psc_total;
                peak_amps = [peak_amps, single_pulse_in_dataset(j).psc_amplitude];
                if (sum(isnan(peak_amps)))
                    error('detected psc has nan peak!, epoch %d \n', single_pulse_in_dataset(j).epoch_id);
                end
                psc_timediff = single_pulse_in_dataset(j).psc_start_ms*1E3 - single_pulse_in_dataset(j).pre_time;
                start_latency = [start_latency, psc_timediff];
                risetime = [risetime, single_pulse_in_dataset(j).psc_risetime_ms];
            end
        end
        R.psc_total_dataset(d) = psc_total;
        R.psc_amp_mean(d) = mean(peak_amps);
        epoch_time_total = (single_pulse_in_dataset(j).pre_time + single_pulse_in_dataset(j).stim_time...
            +single_pulse_in_dataset(j).tail_time)/1E3;
        R.psc_frequency(d) = psc_total/(epoch_time_total*N_epochs_sg);
        R.latency_opto_ms(d) = {start_latency};
        R.opto_duration_ms(d) = single_pulse_in_dataset(j).stim_time;
        R.psc_risetime_mean_s(d) = mean(risetime);

    else
        peak_amps = [];
        psc_total = 0;
        start_latency = [];
        risetime = [];
        R.if_multi_pulse(d) = true;
        pulse_and_down = multi_pulse_in_dataset(1).downtime + ...
            multi_pulse_in_dataset(1).pulse_time;

        for j = 1:N_epochs_mul
            
            if (multi_pulse_in_dataset(j).psc_total~=0)
                psc_total  = psc_total+multi_pulse_in_dataset(j).psc_total;
                peak_amps = [peak_amps, multi_pulse_in_dataset(j).psc_amplitude];
                risetime = [risetime, multi_pulse_in_dataset(j).psc_risetime_ms];

                %special handling of psc timing in multi-pulse senario
                timediff = zeros([1, multi_pulse_in_dataset(j).psc_total]);
                starts = multi_pulse_in_dataset(j).psc_start_ms;
                for n =1:multi_pulse_in_dataset(j).psc_total
                    if (starts(n) < multi_pulse_in_dataset(j).pre_time/1E3)
                        %psc happens before any of the opto pulse is on
                        timediff(n) = starts(n)*1E3-multi_pulse_in_dataset(j).pre_time;
                    else
                        timediff(n) = rem(starts(n)*1E3, pulse_and_down);
                    end
                end
                start_latency = [start_latency, timediff];
            end
        end

        %copy data into R
        R.psc_total_dataset(d) = psc_total;
        R.psc_amp_mean(d) = mean(peak_amps);
        epoch_time_total = N_epochs_mul*(multi_pulse_in_dataset(j).pre_time + multi_pulse_in_dataset(j).stim_time...
            +multi_pulse_in_dataset(j).tail_time)/1E3;
        R.psc_frequency(d) = psc_total/epoch_time_total;
        R.latency_opto_ms(d) = {start_latency};
        R.opto_duration_ms(d) = multi_pulse_in_dataset(j).stim_time;
        R.psc_risetime_mean_s(d) = mean(risetime);

    end
end

end

