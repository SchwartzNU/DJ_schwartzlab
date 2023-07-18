function R = DriftingGratings_CA(data_group, params)
if nargin < 2 || isempty(params)
    binSize = 10;
else
    binSize = params.binSize;
end

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('DriftingGratingsCA',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentEpoch * ...
        aka.BlockParams('DriftingGratings') * ...
        aka.EpochParams('DriftingGratings') & ...
        datasets_struct(d);

    epochs_in_dataset_struct = fetch(epochs_in_dataset,'*');
    epochs_in_dataset_primary = fetch(epochs_in_dataset);


    N_epochs = length(epochs_in_dataset_struct);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    movement_delay = epochs_in_dataset_struct(1).movement_delay;
    pre_time = epochs_in_dataset_struct(1).pre_time;

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
    psth_by_condition = cell(Nconditions,1);
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
                    [psth_x, psth_by_condition{c}] = psth_for_epochs(epochs_in_dataset & epochs_in_dataset_primary(ind), binSize);        

                    %get peak of psth for leading and trailing here
                    psth_x_shifted = psth_x * 1E3 - pre_time; %in ms
                    full_psth_by_condition_x.(condition_name) = psth_x_shifted;
                    full_psth_by_condition_y.(condition_name) = psth_by_condition{c};

                    resting(c) = mean(psth_by_condition{c}(psth_x_shifted<0));

                    %get cycle average here to compute amplitudes and such
                    cycle_period_s = 2 * halfwidth_by_condition(c) / speed_by_condition(c);
                    cycle_period_bins = round(cycle_period_s * 1E3 / binSize);
                    start_point_ms = pre_time + movement_delay;
                    start_bin = round(start_point_ms / binSize);

                    N_bins = length(psth_by_condition{c});
                    bin_ind = start_bin;
                    N_cycles = 0;
                    cycle_avg = zeros(1,cycle_period_bins);
                    while bin_ind + cycle_period_bins < N_bins
                        cycle_avg = cycle_avg + psth_by_condition{c}(bin_ind:bin_ind+cycle_period_bins-1);
                        bin_ind = bin_ind + cycle_period_bins;
                        N_cycles = N_cycles+1;
                    end
                    cycle_avg = cycle_avg / N_cycles;
                    condition_name_cycle = sprintf('speed_%d_direction_%d_halfwidth_%d_contrast_%d',speeds(s),directions(dir),halfwidths(w),contrasts(con));
                    cycle_avg_psth_by_condition.(condition_name_cycle) = cycle_avg;

                    cycle_avg_amplitude(c) = max(cycle_avg);

                    c=c+1;
                end
            end
        end
    end

    %set table variables
    R.stim_condition_list(d) = {{'speed', 'direction', 'halfwidth', 'contrast'}};
    R.baseline_rate_hz(d) = mean(resting);
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
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
    R.cycle_avg_psth_by_condition(d) = {cycle_avg_psth_by_condition};
    R.cycle_avg_amplitude(d) = {cycle_avg_amplitude};
    R.psth_by_condition_x(d) = {full_psth_by_condition_x};
    R.psth_by_condition_y(d) = {full_psth_by_condition_y};

    fprintf('Elapsed time = %d seconds\n', round(toc));
end
