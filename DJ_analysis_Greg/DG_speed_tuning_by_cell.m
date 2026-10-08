function R = DG_speed_tuning_by_cell(data_group, params)
% DG_SPEED_TUNING_BY_CELL
%
% Functions similar to DG_OSI_by_cell.m without filtering speeds
%
% ADDITIONAL OUTPUTS VS DG_OSI_by_cell.m:
%   peak_pref_angle_magnitude_by_condition, peak_avg_magnitude_by_condition
%
%
% RESPONSE MAGNITUDE:
%   Peak-to-peak voltage cycle_avg_amplitude
%      (if want to test deviation from resting later? -->  magnitude = max(|peak_pos - resting|, |peak_neg - resting|)
%   computed per direction, at each speed/halfwidth/contrast condition.
%   Magnitude here is about how far the cell moves from baseline, which is the
%   natural read for a speed-tuning curve.
%
%   peak_avg_magnitude_by_condition
%       Mean of the per-direction magnitude across all tested directions
%       at that condition.
%   peak_pref_angle_magnitude_by_condition
%       Magnitude at the TESTED direction with the largest
%       cycle_avg_amplitude (the discrete argmax)
%
% params.speed_list (optional): restrict to specific speeds rather than
% every speed present in the dataset. Default: use all speeds present.

    if nargin < 2 || ~isfield(params, 'speed_list') || isempty(params.speed_list)
        speed_list = [];  % [] => use every speed present in each dataset
    else
        speed_list = params.speed_list;
    end

    % 1. Which datasets are we working on?
    datasets = aka.Dataset & data_group;
    datasets_struct = fetch(datasets);
    N_datasets = datasets.count;

    % 2. Ask for an empty results table shaped like the template.
    R = sln_results.table_definition_from_template('DG_speed_tuning_by_cell', N_datasets);

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

        all_speeds = round([epochs_in_dataset_struct.grating_speed]);
        if isempty(speed_list)
            speeds = sort(unique(all_speeds));
        else
            speeds = sort(speed_list(:)');
        end
        N_speeds = length(speeds);

        all_directions = round([epochs_in_dataset_struct.grating_angle]);
        directions = sort(unique(all_directions));

        all_halfwidths = round([epochs_in_dataset_struct.cycle_half_width]);
        halfwidths = sort(unique(all_halfwidths));
        N_halfwidths = length(halfwidths);

        all_contrasts = round([epochs_in_dataset_struct.contrast]);
        contrasts = sort(unique(all_contrasts));
        N_contrasts = length(contrasts);

        Nconditions = N_speeds * N_halfwidths * N_contrasts;
        speed_by_condition = zeros(Nconditions, 1);
        halfwidth_by_condition = zeros(Nconditions, 1);
        contrast_by_condition = zeros(Nconditions, 1);
        preferred_angle_by_condition = nan(Nconditions, 1);
        preferred_orientation_by_condition = nan(Nconditions, 1);
        dsi_by_condition = nan(Nconditions, 1);
        osi_by_condition = nan(Nconditions, 1);
        peak_pref_angle_magnitude_by_condition = nan(Nconditions, 1);
        peak_avg_magnitude_by_condition = nan(Nconditions, 1);

        c = 1;
        for s = 1:N_speeds
            for w = 1:N_halfwidths
                for con = 1:N_contrasts
                    speed_by_condition(c) = speeds(s);
                    halfwidth_by_condition(c) = halfwidths(w);
                    contrast_by_condition(c) = contrasts(con);

                    cycle_avg_amplitude = compute_cycle_avg_amp_by_direction( ...
                            epochs_in_dataset_struct, all_directions, all_halfwidths, all_contrasts, ...
                            directions, halfwidths(w), contrasts(con), speeds(s), ...
                            sample_rate, pre_time, movement_delay, all_speeds);

                    % ALTERNATIVE (magnitude as deviation from resting)
                    %
                    % [cycle_avg_amplitude, peak_pos_by_direction, peak_neg_by_direction, resting_by_direction] = ...
                    %       compute_cycle_avg_amplitude_by_direction( ...
                    %           epochs_in_dataset_struct, all_directions, all_halfwidths, all_contrasts, ...
                    %           directions, halfwidths(w), contrasts(con), speeds(s), ...
                    %           sample_rate, pre_time, movement_delay, all_speeds);

                    valid = ~isnan(cycle_avg_amplitude);

                    if ~any(valid) || sum(cycle_avg_amplitude(valid)) == 0
                        % no epochs matched this speed/halfwidth/contrast
                        % (e.g. speed not tested for this dataset) -- leave
                        % this condition's outputs as NaN and move on
                        c = c + 1;
                        continue;
                    end

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

                    % --- response magnitude: peak-to-peak amplitude ---
                    peak_avg_magnitude = mean(amp);
                    peak_pref_angle_magnitude = max(amp);

                    % ALTERNATIVE (magnitude as deviation from resting)
                    % 
                    % magnitude_by_direction = max( ...
                    %       abs(peak_pos_by_direction - resting_by_direction), ...
                    %       abs(peak_neg_by_direction - resting_by_direction));
                    %   peak_avg_magnitude = mean(magnitude_by_direction(valid));
                    %   valid_idx = find(valid);
                    %   [~, local_max_idx] = max(amp);
                    %   peak_direction_idx = valid_idx(local_max_idx);
                    %   peak_pref_angle_magnitude = magnitude_by_direction(peak_direction_idx);

                    preferred_angle_by_condition(c) = pref_angle;
                    preferred_orientation_by_condition(c) = pref_orientation;
                    dsi_by_condition(c) = dsi;
                    osi_by_condition(c) = osi;
                    peak_pref_angle_magnitude_by_condition(c) = peak_pref_angle_magnitude;
                    peak_avg_magnitude_by_condition(c) = peak_avg_magnitude;

                    c = c + 1;
                end
            end
        end

        % set table variables
        R.file_name{d} = datasets_struct(d).file_name;
        R.dataset_name{d} = datasets_struct(d).dataset_name;
        R.source_id(d) = datasets_struct(d).source_id;
        R.speeds{d} = speeds;
        R.halfwidths{d} = halfwidths';
        R.contrasts{d} = contrasts';
        R.speed_by_condition{d} = speed_by_condition;
        R.halfwidth_by_condition{d} = halfwidth_by_condition;
        R.contrast_by_condition{d} = contrast_by_condition;
        R.preferred_angle_by_condition{d} = preferred_angle_by_condition;
        R.preferred_orientation_by_condition{d} = preferred_orientation_by_condition;
        R.dsi_by_condition{d} = dsi_by_condition;
        R.osi_by_condition{d} = osi_by_condition;
        R.peak_pref_angle_magnitude_by_condition{d} = peak_pref_angle_magnitude_by_condition;
        R.peak_avg_magnitude_by_condition{d} = peak_avg_magnitude_by_condition;

        fprintf('Elapsed time = %d seconds\n', round(toc));
    end
end