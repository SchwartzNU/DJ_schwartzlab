function R = DriftingGratings_CC(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('DriftingGratingsCC',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.DriftingGratingsparams & ...
        datasets_struct(d);
    epochs_in_dataset_struct = fetch(epochs_in_dataset,'*');

    N_epochs = length(epochs_in_dataset_struct);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    sample_rate = epochs_in_dataset_struct(1).sample_rate;
    movement_delay = epochs_in_dataset_struct(1).movement_delay;
    pre_time = epochs_in_dataset_struct(1).pre_time;
    %tail_time = epochs_in_dataset_struct(1).tail_time;
    pre_samples = sample_rate * (pre_time / 1E3);

    all_speeds = round([epochs_in_dataset_struct.grating_speed]);
    speeds = sort(unique(all_speeds));
    N_speeds = length(speeds);

    all_directions = round([epochs_in_dataset_struct.grating_angle]);
    directions = sort(unique(all_directions));
    N_directions = length(directions);

    all_halfwidths = round([epochs_in_dataset_struct.cycle_half_width]);
    halfwidths = sort(unique(all_halfwidths));
    N_halfwidths = length(halfwidths);

    all_contrasts = round([epochs_in_dataset_struct.contrast]);
    contrasts = sort(unique(all_contrasts));
    N_contrasts = length(contrasts);

    Nconditions = N_speeds * N_directions * N_halfwidths * N_contrasts;

    N_epochs_per_condition = zeros(Nconditions,1);
    speed_by_condition = zeros(Nconditions,1);
    direction_by_condition = zeros(Nconditions,1);
    halfwidth_by_condition = zeros(Nconditions,1);
    contrast_by_condition = zeros(Nconditions,1);
    cycle_avg_amplitude = zeros(Nconditions,1);
    cycle_avg_peak_pos = zeros(Nconditions,1);
    cycle_avg_peak_neg = zeros(Nconditions,1);
    resting = zeros(Nconditions,1);

    c = 1;
    for s=1:N_speeds
        for dir = 1:N_directions
            for w = 1:N_halfwidths
                for con = 1:N_contrasts
                    condition_name = sprintf('speed_%d_direction_%d_halfwidth_%d_contrast_%d',speeds(s),directions(dir),halfwidths(w),contrasts(con));
                    speed_by_condition(c) = speeds(s);
                    direction_by_condition(c) = directions(dir);
                    halfwidth_by_condition(c) = halfwidths(w);
                    contrast_by_condition(c) = contrasts(con);
                    ind = find(all_speeds == speeds(s) & all_directions == directions(dir) & all_halfwidths == halfwidths(w) & all_contrasts == contrasts(con));

                    N_epochs_per_condition(c) = length(ind);

                    mean_trace = mean(reshape([epochs_in_dataset_struct(ind).raw_data], [], length(ind)), 2)';
                    example_trace_by_condition.(condition_name) = epochs_in_dataset_struct(ind(1)).raw_data;
                    resting(c) = mean(mean_trace(1:pre_samples));

                    %get cycle average here to compute amplitudes and such
                    cycle_period_s = 2 * halfwidth_by_condition(c) / speed_by_condition(c);
                    cycle_period_samples = round(cycle_period_s * sample_rate);
                    start_point_ms = pre_time + movement_delay;
                    start_sample = round((start_point_ms / 1E3) * sample_rate);

                    N_samples = length(mean_trace);
                    sample_ind = start_sample;
                    N_cycles = 0;
                    cycle_avg = zeros(1,cycle_period_samples);
                    while sample_ind + cycle_period_samples < N_samples
                        cycle_avg = cycle_avg + mean_trace(sample_ind:sample_ind+cycle_period_samples-1);
                        sample_ind = sample_ind + cycle_period_samples;
                        N_cycles = N_cycles+1;
                    end
                    cycle_avg = cycle_avg / N_cycles;
                    condition_name_cycle = sprintf('speed_%d_direction_%d_halfwidth_%d_contrast_%d',speeds(s),directions(dir),halfwidths(w),contrasts(con));
                    cycle_avg_trace_by_condition.(condition_name_cycle) = cycle_avg;

                    cycle_avg_amplitude(c) = range(cycle_avg);
                    cycle_avg_peak_pos(c) = max(cycle_avg);
                    cycle_avg_peak_neg(c) = min(cycle_avg);

                    c=c+1;
                end
            end
        end
    end

    %set table variables
    R.stim_condition_list(d) = {{'speed', 'direction', 'halfwidth', 'contrast'}};
    R.mean_resting_potential(d) = mean(resting);
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.sample_rate(d) = sample_rate;
    R.pre_time_ms(d) = pre_time;
    R.movement_delay_ms(d) = movement_delay;
    R.speeds{d} = speeds';
    R.directions{d} = directions';
    R.halfwidths{d} = halfwidths';
    R.contrasts{d} = contrasts';
    R.speed_by_condition(d) = {speed_by_condition};
    R.direction_by_condition(d) = {direction_by_condition};
    R.halfwidth_by_condition(d) = {halfwidth_by_condition};
    R.contrast_by_condition(d) = {contrast_by_condition};    
    R.n_epochs_per_condition(d) = {N_epochs_per_condition};
    R.example_trace_by_condition(d) = {example_trace_by_condition};
    R.cycle_avg_trace_by_condition(d) = {cycle_avg_trace_by_condition};
    R.cycle_avg_amplitude(d) = {cycle_avg_amplitude};
    R.cycle_avg_peak_pos(d) = {cycle_avg_peak_pos};
    R.cycle_avg_peak_neg(d) = {cycle_avg_peak_neg};
    R.resting_potential_mean(d) = mean(resting);

    fprintf('Elapsed time = %d seconds\n', round(toc));
end
