function R = DG_OSI_by_cell(data_group, params)

% In: a data_group (set of datasets). Out: a table (from the results
% template) with one row per dataset, giving preferred direction, DSI,
% and OSI at a fixed grating speed, for each halfwidth/contrast condition
% present at that speed.
%
% For now speed is fixed at 1200
% um/s -- pass params.speed to override once ready to generalize.
%
% DSI/OSI use the standard circular-vector method
%   DSI uses the raw angle:      vector = sum( R(theta) * exp(i*theta) )
%   OSI uses the doubled angle:  vector = sum( R(theta) * exp(i*2*theta) )
%                                 (folds opposite directions together)
% where R(theta) is cycle_avg_amplitude (mV) at each direction.
% Preferred angle reported here is the DSI vector's angle (0-360 deg) --
% the standard "preferred direction," not a separately-folded orientation.

    if nargin < 2 || ~isfield(params, 'speed')
        speed_to_use = 1200;
    else
        speed_to_use = params.speed;
    end

    % 1. Which datasets are we working on?
    datasets = aka.Dataset & data_group;
    datasets_struct = fetch(datasets);
    N_datasets = datasets.count;

    % 2. Ask for an empty results table shaped like the template.
    R = sln_results.table_definition_from_template('DG_OSI_by_cell', N_datasets);

    % 3. Fill it in, one dataset (one row) at a time.
    for d = 1:N_datasets
        tic;
        fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, ...
            datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

        epochs_in_dataset = sln_symphony.DatasetEpoch * ...
            sln_symphony.ExperimentEpoch * ...
            sln_symphony.ExperimentChannel * ...
            sln_symphony.ExperimentEpochChannel * ...
            aka.DriftingGratingsparams & ...
            datasets_struct(d);
        epochs_in_dataset_struct = fetch(epochs_in_dataset, '*');

        N_epochs = length(epochs_in_dataset_struct);
        if N_epochs == 0
            error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
        end

        sample_rate = epochs_in_dataset_struct(1).sample_rate;
        movement_delay = epochs_in_dataset_struct(1).movement_delay;
        pre_time = epochs_in_dataset_struct(1).pre_time;

        % restrict to the fixed speed for this analysis
        all_speeds = round([epochs_in_dataset_struct.grating_speed]);
        speed_match = all_speeds == speed_to_use;

        if ~any(speed_match)
            warning('No epochs at speed=%d for dataset %s; skipping this dataset.', ...
                speed_to_use, datasets_struct(d).dataset_name);
            R.file_name{d} = datasets_struct(d).file_name;
            R.dataset_name{d} = datasets_struct(d).dataset_name;
            R.source_id(d) = datasets_struct(d).source_id;
            R.speed_used(d) = speed_to_use;
            R.halfwidths{d} = [];
            R.contrasts{d} = [];
            R.halfwidth_by_condition{d} = [];
            R.contrast_by_condition{d} = [];
            R.preferred_angle_by_condition{d} = [];
            R.preferred_orientation_by_condition{d} = [];
            R.dsi_by_condition{d} = [];
            R.osi_by_condition{d} = [];
            continue;
        end

        epochs_in_dataset_struct = epochs_in_dataset_struct(speed_match);
        N_epochs = length(epochs_in_dataset_struct);

        all_directions = round([epochs_in_dataset_struct.grating_angle]);
        directions = sort(unique(all_directions));
        N_directions = length(directions);

        all_halfwidths = round([epochs_in_dataset_struct.cycle_half_width]);
        halfwidths = sort(unique(all_halfwidths));
        N_halfwidths = length(halfwidths);

        all_contrasts = round([epochs_in_dataset_struct.contrast]);
        contrasts = sort(unique(all_contrasts));
        N_contrasts = length(contrasts);

        pre_samples = sample_rate * (pre_time / 1E3);

        Nconditions = N_halfwidths * N_contrasts;
        halfwidth_by_condition = zeros(Nconditions, 1);
        contrast_by_condition = zeros(Nconditions, 1);
        preferred_angle_by_condition = zeros(Nconditions, 1);
        preferred_orientation_by_condition = zeros(Nconditions,1);
        dsi_by_condition = zeros(Nconditions, 1);
        osi_by_condition = zeros(Nconditions, 1);

        c = 1;
        for w = 1:N_halfwidths
            for con = 1:N_contrasts
                % compute cycle_avg_amplitude at each direction, for this
                % halfwidth/contrast, exactly as DriftingGratings_CC.m does
                cycle_avg_amplitude = zeros(N_directions, 1);

                for dir = 1:N_directions
                    ind = find(all_directions == directions(dir) & ...
                        all_halfwidths == halfwidths(w) & ...
                        all_contrasts == contrasts(con));

                    if isempty(ind)
                        cycle_avg_amplitude(dir) = NaN;
                        continue;
                    end

                    mean_trace = mean(reshape([epochs_in_dataset_struct(ind).raw_data], [], length(ind)), 2)';

                    cycle_period_s = 2 * halfwidths(w) / speed_to_use;
                    cycle_period_samples = round(cycle_period_s * sample_rate);
                    start_point_ms = pre_time + movement_delay;
                    start_sample = round((start_point_ms / 1E3) * sample_rate);

                    N_samples = length(mean_trace);
                    sample_ind = start_sample;
                    N_cycles = 0;
                    cycle_avg = zeros(1, cycle_period_samples);
                    while sample_ind + cycle_period_samples < N_samples
                        cycle_avg = cycle_avg + mean_trace(sample_ind:sample_ind+cycle_period_samples-1);
                        sample_ind = sample_ind + cycle_period_samples;
                        N_cycles = N_cycles + 1;
                    end
                    cycle_avg = cycle_avg / N_cycles;

                    cycle_avg_amplitude(dir) = range(cycle_avg);
                end

                % drop any directions with no matching epochs before the vector sum
                valid = ~isnan(cycle_avg_amplitude);
                theta = deg2rad(directions(valid))';
                amp = cycle_avg_amplitude(valid);

                % --- DSI: raw-angle vector sum (direction, 0-360 deg) ---
                dsi_vector = sum(amp .* exp(1i * theta));
                dsi = abs(dsi_vector) / sum(amp);
                pref_angle = mod(rad2deg(angle(dsi_vector)), 360);

                % --- OSI: doubled-angle vector sum (folds 0/180 together) ---
                osi_vector = sum(amp .* exp(1i * 2 * theta));
                osi = abs(osi_vector) / sum(amp);
                pref_orientation = mod(rad2deg(angle(osi_vector)) / 2, 180);

                halfwidth_by_condition(c) = halfwidths(w);
                contrast_by_condition(c) = contrasts(con);
                preferred_angle_by_condition(c) = pref_angle;
                preferred_orientation_by_condition(c) = pref_orientation;
                dsi_by_condition(c) = dsi;
                osi_by_condition(c) = osi;

                c = c + 1;
            end
        end

        % set table variables
        R.file_name{d} = datasets_struct(d).file_name;
        R.dataset_name{d} = datasets_struct(d).dataset_name;
        R.source_id(d) = datasets_struct(d).source_id;
        R.speed_used(d) = speed_to_use;
        R.halfwidths{d} = halfwidths';
        R.contrasts{d} = contrasts';
        R.halfwidth_by_condition{d} = halfwidth_by_condition;
        R.contrast_by_condition{d} = contrast_by_condition;
        R.preferred_angle_by_condition{d} = preferred_angle_by_condition;
        R.preferred_orientation_by_condition{d} = preferred_orientation_by_condition
        R.dsi_by_condition{d} = dsi_by_condition;
        R.osi_by_condition{d} = osi_by_condition;

        fprintf('Elapsed time = %d seconds\n', round(toc));
    end
end
