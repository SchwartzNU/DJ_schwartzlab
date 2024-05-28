function required_fields = plot_TransporterCurrent_Plotter(R, ax)
    d = 1;
    if nargin < 1
        required_fields = {'sample_rate', 'example_traces', 'inj_current', 'pre_time_ms', 'stim_end_idx', 'vrest_example', 'example_ahp'};
        return;
    end

    % Ensure all required fields are present
    required_fields = {'sample_rate', 'example_traces', 'inj_current', 'pre_time_ms', 'stim_end_idx', 'vrest_example', 'example_ahp'};
    for field = required_fields
        if ~isfield(R, field{1})
            error(['Missing required field: ', field{1}]);
        end
    end

    set(ax, 'XLim', [-inf inf]);
    traces = R.example_traces(d, :);
    [num_rows, ~] = size(traces);
    stim_end_idx = R.stim_end_idx(d);
    vrest = R.vrest_example;
    sample_rate = R.sample_rate(d);
    currents = R.inj_current;
    ahp_areas = R.example_ahp;
    hold(ax, 'on');
    set(ax, 'XtickMode', 'auto');
    set(ax, 'YtickMode', 'auto');

    fig = ax.Parent;  % Get the figure handle from the provided axes

    %% Plot with inset
    for s = 1:num_rows
        trace = traces(s, :);
        current = currents(s);
        spike_count = R.example_spike_count(s, :);
        ahp_area = ahp_areas(s);
        x = (0:length(trace) - 1) ./ sample_rate; % Transform indices to actual time
        segment_length = length(trace(stim_end_idx:end));
        vrest_line = vrest(s) * ones(1, segment_length);
        trace_segment = trace(stim_end_idx:end);
        trace_segment = min(trace_segment, vrest_line);

        %% Main plot
        h_trace = plot(ax, x, trace, 'b');
        t = R.example_sp(s, :);
        t_valid = t > 0;
        t = t(t_valid);
        plot(ax, x(t), trace(t), 'ro');
        step_size = 1000; % Define the step size
        x_fill = x(stim_end_idx:step_size:end); % Use every 10th index
        y_fill = trace_segment(1:step_size:end); % Use every 10th index

        h_fill = fill(ax, [x_fill, fliplr(x_fill)], [y_fill, fliplr(vrest_line(1:step_size:end))], 'b', 'FaceAlpha', 0.3);
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Voltage (mV)');
        title(ax, ['sAHP, Current: ' num2str(current, '%.2f pA') ', Spikes: ' num2str(spike_count)]);
        v_line = xline(ax, x(stim_end_idx), 'g-', 'LineWidth', 2);
        h_line = yline(ax, vrest(s), 'r-', 'LineWidth', 2);
        legend(ax, [h_trace, h_fill, v_line, h_line], {'Trace', ['Shaded AHP Area: ' num2str(ahp_area, '%.2f')], 'Stimulus End', ['Resting Voltage: ' num2str(vrest(s), '%.2f') ' mV']}, 'Location', 'best');

        %% Inset for zoomed-in view
        inset_ax = axes('Position', [0.51, 0.33, 0.45, 0.25], 'Parent', fig);  % Adjust the position and size as needed
        box(inset_ax, 'on');
        hold(inset_ax, 'on');
        plot(inset_ax, x, trace, 'b');
        fill(inset_ax, [x_fill, fliplr(x_fill)], [y_fill, fliplr(vrest_line(1:step_size:end))], 'b', 'FaceAlpha', 0.3);
        
        % Set x and y limits to zoom in on the shaded area
        xlim(inset_ax, [min(x_fill), max(x_fill)]);
        ylim(inset_ax, [min(y_fill) - 5, max(y_fill) + 5]);  % Adjust padding as needed

        xlabel(inset_ax, 'Time (s)');
        ylabel(inset_ax, 'Voltage (mV)');
        title(inset_ax, 'Zoomed View of AHP');
        hold(inset_ax, 'off');
    end
    hold(ax, 'off');
end










