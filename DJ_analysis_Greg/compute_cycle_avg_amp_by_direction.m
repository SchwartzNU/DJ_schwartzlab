function [cycle_avg_amplitude, peak_pos_by_direction, peak_neg_by_direction, resting_by_direction, cycle_avg_trace_by_direction] = compute_cycle_avg_amp_by_direction( ...
    epochs_struct, all_directions, all_halfwidths, all_contrasts, ...
    directions, halfwidth, contrast, speed, sample_rate, pre_time, movement_delay, all_speeds)
% COMPUTE_CYCLE_AVG_AMP_BY_DIRECTION
% For one fixed halfwidth/contrast/speed condition, computes
% the cycle-averaged response amplitude (mV) at each requested direction,
% plus the per-direction peak (+/-) values and resting potential needed to
% compute a response magnitude relative to baseline.
%
% INPUTS
%   epochs_struct  - struct array of epochs (output of fetch(...,'*')).
%                    May already be filtered to a single speed (as
%                    DG_OSI_by_cell.m does), or span multiple speeds if
%                    all_speeds (below) is also provided.
%   all_directions, all_halfwidths, all_contrasts
%                  - per-epoch condition vectors (round(...) already
%                    applied), same length and order as epochs_struct
%   directions     - vector of direction values (deg) to compute an
%                    amplitude for, in the order results should come back
%   halfwidth, contrast, speed
%                  - the fixed condition to compute at (scalars)
%   sample_rate, pre_time, movement_delay
%                  - same units as in DriftingGratings_CC.m
%                    (pre_time/movement_delay in ms)
%   all_speeds     - OPTIONAL. Per-epoch grating_speed vector (round(...)
%                    applied), same length/order as epochs_struct. Pass
%                    this when epochs_struct spans multiple speeds (e.g.
%                    DG_speed_tuning_by_cell.m), so this function also
%                    filters by speed==<speed> when selecting epochs. If
%                    omitted, no speed-based filtering is applied here --
%                    this preserves DG_OSI_by_cell.m's original behavior,
%                    which pre-filters epochs_struct to a single speed
%                    before calling this function.
%
% OUTPUTS
%   cycle_avg_amplitude
%       vector, one entry per element of `directions`. Each entry is
%       range(cycle_avg) in mV (peak-to-peak), or NaN if no epochs matched.
%   peak_pos_by_direction, peak_neg_by_direction
%       max(cycle_avg) / min(cycle_avg) per direction, NaN if no match.
%   resting_by_direction
%       mean membrane potential during the pre-stimulus period, computed
%       from the same per-direction mean_trace used for cycle averaging.
%   cycle_avg_trace_by_direction (optional)
%       struct with one field per direction (named 'dir_<deg>') holding
%       that direction's cycle-averaged trace. Only computed if requested
%       (nargout > 4), so callers that don't need traces don't pay for
%       storing them.

    if nargin < 12
        all_speeds = [];
    end
    filter_by_speed = ~isempty(all_speeds);

    N_directions = length(directions);
    cycle_avg_amplitude = nan(N_directions, 1);
    peak_pos_by_direction = nan(N_directions, 1);
    peak_neg_by_direction = nan(N_directions, 1);
    resting_by_direction = nan(N_directions, 1);

    want_traces = nargout > 4;
    if want_traces
        cycle_avg_trace_by_direction = struct();
    end

    pre_samples = sample_rate * (pre_time / 1E3);

    for dir_idx = 1:N_directions
        match = all_directions == directions(dir_idx) & ...
            all_halfwidths == halfwidth & ...
            all_contrasts == contrast;
        if filter_by_speed
            match = match & all_speeds == speed;
        end
        ind = find(match);

        if isempty(ind)
            continue; % leave as NaN
        end

        mean_trace = mean(reshape([epochs_struct(ind).raw_data], [], length(ind)), 2)';
        resting_by_direction(dir_idx) = mean(mean_trace(1:pre_samples));

        cycle_period_s = 2 * halfwidth / speed;
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

        cycle_avg_amplitude(dir_idx) = range(cycle_avg);
        peak_pos_by_direction(dir_idx) = max(cycle_avg);
        peak_neg_by_direction(dir_idx) = min(cycle_avg);

        if want_traces
            field_name = sprintf('dir_%d', round(directions(dir_idx)));
            cycle_avg_trace_by_direction.(field_name) = cycle_avg;
        end
    end
end