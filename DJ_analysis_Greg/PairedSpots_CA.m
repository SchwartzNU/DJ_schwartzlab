function R = PairedSpots_CA(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('PairedSpots_CA',N_datasets);
for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        aka.PairedSpotsParams & ...
        datasets_struct(d),'*');

    N_epochs = length(epochs_in_dataset);

    for i=1:N_epochs
        fprintf('working on epoch %d.\n', i);
        if i==1 %setup stuff for first epoch
            meanLevel = epochs_in_dataset(i).mean_level;
            spot_contrast = (epochs_in_dataset(i).epoch_intensity - meanLevel) / meanLevel;
            contrasts = sort(unique(spot_contrast),'asc');
            Ncontrasts = length(contrasts);
            empty_dict_single = configureDictionary('string','struct');
            empty_dict_paired = configureDictionary('string','struct');
            empty_single_struct = struct('resp', []);
            empty_pair_struct = struct('distance',[], ...
                'resp',[], ...
                'center', []);
            for c=1:Ncontrasts
                single_spot_data{c} = empty_dict_single;
                paired_spot_data{c} = empty_dict_paired;
            end
        end
        ep_data = sln_symphony.ExperimentEpochChannel * ...
            sln_symphony.ExperimentElectrode * ... 
            sln_symphony.SpikeTrain * ...  
            sln_symphony.ExperimentChannel & epochs_in_dataset(i);
        if ~exists(ep_data)
            error("No SpikeTrain table found for epoch %d\n.",epochs_in_dataset(i).epoch_number);
        end
        sp = fetch1(ep_data,'spike_indices');
        spot_size = epochs_in_dataset(i).spot_size;
        rstar_mean = epochs_in_dataset(i).rstar_mean;
        frame_rate = 60; %Hz
        sample_rate = fetch1(ep_data,'sample_rate');
        pre_ms = epochs_in_dataset(i).pre_time;
        spot_pre_frames = epochs_in_dataset(i).spot_pre_frames;
        spot_stim_frames = epochs_in_dataset(i).spot_stim_frames;
        spot_tail_frames = epochs_in_dataset(i).spot_tail_frames;

        % ep_raw = fetch1(ep_data, raw_data)

        x_temp = reshape(epochs_in_dataset(i).cx,2,[]);
        spotA_x = round(x_temp(1,:)); spotB_x = round(x_temp(1,:));
        y_temp = reshape(epochs_in_dataset(i).cy,2,[]);
        spotA_y = round(y_temp(1,:)); spotB_y = round(y_temp(2,:));
        spot_contrast = (epochs_in_dataset(i).epoch_intensity - meanLevel) / meanLevel;
        single_spot = spotA_x == spotB_x & spotA_y == spotB_y;

        Nspots = length(spot_contrast);
        for s=1:Nspots
            contrast_ind = find(contrasts==spot_contrast(s));
            if single_spot(s)
                this_key = sprintf('%d,%d',spotA_x(s),spotA_y(s));
                if isKey(single_spot_data{contrast_ind},this_key) %existing entry
                    single_struct = single_spot_data{contrast_ind}(this_key);
                    single_struct.resp = [single_struct.resp; response_for_spot(sp, ...
                        sample_rate, ...
                        frame_rate, ...
                        pre_ms, ...
                        spot_pre_frames, ...
                        spot_stim_frames, ...
                        spot_tail_frames, ...
                        s);];
                else %new entry
                    single_struct = empty_single_struct;
                    single_struct.resp = response_for_spot(sp, ...
                        sample_rate, ...
                        frame_rate, ...
                        pre_ms, ...
                        spot_pre_frames, ...
                        spot_stim_frames, ...
                        spot_tail_frames, ...
                        s);
                end
                single_spot_data{contrast_ind}(this_key) = single_struct;
            else %paired spots
                this_key = sprintf('%d,%d;%d,%d',spotA_x(s),spotA_y(s),spotB_x(s),spotB_y(s));
                if isKey(paired_spot_data{contrast_ind},this_key) %existing entry
                    pair_struct = paired_spot_data{contrast_ind}(this_key);
                    pair_struct.resp = [pair_struct.resp; response_for_spot(sp, ...
                        sample_rate, ...
                        frame_rate, ...
                        pre_ms, ...
                        spot_pre_frames, ...
                        spot_stim_frames, ...
                        spot_tail_frames, ...
                        s);];
                else %new entry
                    pair_struct = empty_pair_struct;
                    pair_struct.distance = pdist2([spotA_x(s),spotA_y(s)],[spotB_x(s),spotB_y(s)]);
                    pair_struct.center = [mean([spotA_x(s),spotB_x(s)]), mean([spotA_y(s),spotB_y(s)])];
                    pair_struct.resp = response_for_spot(sp, ...
                        sample_rate, ...
                        frame_rate, ...
                        pre_ms, ...
                        spot_pre_frames, ...
                        spot_stim_frames, ...
                        spot_tail_frames, ...
                        s);
                end
                paired_spot_data{contrast_ind}(this_key) = pair_struct;
            end

        end
        %keyboard;

    end

    %set table variables
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name(d) = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.sample_rate(d) = sample_rate;
    R.n_epochs(d) = N_epochs;
    R.spot_size(d) = spot_size;
    R.rstar_mean(d) = rstar_mean;
    R.contrasts{d} = contrasts;
    R.spot_pre_frames(d) = spot_pre_frames;
    R.spot_stim_frames(d) = spot_stim_frames;
    R.spot_tail_frames(d) = spot_tail_frames;
    R.single_spot_data{d} = single_spot_data;
    R.paired_spot_data{d} = paired_spot_data;
end

    function val = response_for_spot(sp, ...
            sample_rate, ...
            frame_rate, ...
            pre_ms, ...
            spot_pre_frames, ...
            spot_stim_frames, ...
            spot_tail_frames, ...
            spot_number)
        
        frame_samples = sample_rate / frame_rate;  
        start_sample = pre_ms / 1E3 * sample_rate + ...
            frame_samples * ...
            ((spot_pre_frames + spot_stim_frames + spot_tail_frames) * (spot_number - 1) + ...
            spot_pre_frames);
        start_sample = round(start_sample);
        end_sample = start_sample + round(frame_samples * (spot_stim_frames + spot_tail_frames));

        val = sum(sp >= start_sample & sp < end_sample);        
    end

end