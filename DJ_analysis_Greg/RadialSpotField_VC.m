function R = RadialSpotField_VC(data_group, params)
frame_rate = 60; %Hz

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('RadialSpots_VC',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.EpochParams('SpotField') * aka.BlockParams('SpotField') & ...
        datasets_struct(d),'*');

    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end
    
    %parameters to save for the whole dataset
    N_spots = epochs_in_dataset(1).spots_per_arm * epochs_in_dataset(1).arms;
    sample_rate = epochs_in_dataset(1).sample_rate;
    rstar_intensity_spot = epochs_in_dataset(1).rstar_intensity_spot;
    spot_pre_frames = epochs_in_dataset(1).spot_pre_frames;
    spot_stim_frames = epochs_in_dataset(1).spot_stim_frames;
    spot_tail_frames = epochs_in_dataset(1).spot_tail_frames;
    spot_size = epochs_in_dataset(1).spot_size;

    %get all spot locations from first epoch
    all_points = [epochs_in_dataset(1).cx', epochs_in_dataset(1).cy'];
    all_points_unique = unique(all_points,'rows');
   
    all_dist = round(pdist2(all_points,[0,0]));
    all_dist_unique = unique(round(pdist2(all_points_unique,[0,0])));
    
    all_ang = round(cart2pol(all_points(:,1),all_points(:,2)),4);
    all_ang_unique = unique(round(cart2pol(all_points_unique(:,1),all_points_unique(:,2)),4));
    
    N_ang = length(all_ang_unique);
    N_dist = length(all_dist_unique);

    trace_tensor = cell(N_ang, N_dist, N_epochs);
    peak_tensor = zeros(N_ang, N_dist, N_epochs);
    spike_count_tensor = zeros(N_ang, N_dist, N_epochs);

    trace_matrix_mean = cell(N_ang, N_dist);
    trace_matrix_sem = cell(N_ang, N_dist);

    peak_matrix_mean = zeros(N_ang, N_dist);
    peak_matrix_sem = zeros(N_ang, N_dist);
   
    spot_period_samples = (spot_pre_frames+spot_stim_frames+spot_tail_frames) / frame_rate * sample_rate;
    pre_samples = spot_pre_frames / frame_rate * sample_rate;
    stim_samples = spot_stim_frames / frame_rate * sample_rate;
    tail_samples = spot_tail_frames / frame_rate * sample_rate;

    filter_length = 5 * sample_rate / 1E3;
    
    for ep=1:N_epochs
        ind = 1;

        all_points = [epochs_in_dataset(ep).cx', epochs_in_dataset(ep).cy'];
        all_dist = round(pdist2(all_points,[0,0]));
        all_ang = round(cart2pol(all_points(:,1),all_points(:,2)),4);

        for s=1:N_spots
            ind_ang = find(all_ang_unique == all_ang(s));
            ind_dist = find(all_dist_unique == all_dist(s));

            start_sample = ind;
            end_sample = start_sample + spot_period_samples - 1;

            baseline = mean(epochs_in_dataset(ep).raw_data(start_sample:start_sample+pre_samples-1));
            %trace = movmedian(epochs_in_dataset(ep).raw_data(start_sample:end_sample), filter_length, 'Endpoints', baseline);
            trace = epochs_in_dataset(ep).raw_data(start_sample:end_sample);
            trace_tensor{ind_ang, ind_dist, ep} = trace - baseline;
            peak_tensor(ind_ang, ind_dist, ep) = abs(min(trace - baseline)); %negative (inward) currents

            ind = ind + spot_period_samples;
        end
    end
    peak_matrix_mean = mean(peak_tensor,3);
    if N_epochs>1
        peak_matrix_sem = std(peak_tensor,[],3) ./ sqrt(N_epochs-1);
        for i=1:N_ang
            for j=1:N_dist
                t = vertcat(trace_tensor{i, j, :});
                if ~isempty(t)
                    trace_matrix_mean = mean(t,1);
                    trace_matrix_sem = std(t,[],1) ./ sqrt(N_epochs-1);                    
                end
            end
        end
    else
        trace_matrix_mean = trace_tensor{:,:,1};
    end
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.sample_rate(d) = sample_rate;
    R.trace_matrix_mean{d} = trace_matrix_mean;
    R.trace_matrix_sem{d} = trace_matrix_sem;
    R.peak_matrix_mean{d} = peak_matrix_mean;
    R.peak_matrix_sem{d} = peak_matrix_sem;
    R.spot_dist{d} = all_dist_unique;
    R.spot_ang{d} = all_ang_unique;
    R.rstar_intensity_spot(d) = rstar_intensity_spot;
    R.spot_size(d) = spot_size;
    R.n_epochs(d) = N_epochs;
    R.pre_time_ms(d) = 1E3 * pre_samples / sample_rate;
    R.stim_time_ms(d) = 1E3 * stim_samples / sample_rate;
    R.tail_time_ms(d) = 1E3 * tail_samples / sample_rate;

    fprintf('Elapsed time = %d seconds\n', round(toc));
end


