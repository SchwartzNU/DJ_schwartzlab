function required_fields = plot_DriftingGratings_MultiCondition_CA_amplitude(R,condition_struct,ax)
if nargin < 1
    required_fields = {'cycle_avg_amplitude', ...
        'speeds', 'directions', 'halfwidths', 'contrasts'};
    return;
end

val_set = R.cycle_avg_amplitude;
polar = false;

if strcmp(condition_struct.speed,'plot all')
    x_vals = R.speeds;
    x_title = 'Speed (µm/s)';
    N_vals = length(R.speeds);
    values = zeros(N_vals,1);
    
    for i=1:N_vals
        ind = R.speed_by_condition == R.speeds(i) & ...
            R.direction_by_condition == str2double(condition_struct.direction) & ...
            R.halfwidth_by_condition == str2double(condition_struct.halfwidth) & ...
            R.contrast_by_condition == str2double(condition_struct.contrast);
        values(i) = val_set(ind);
    end

elseif strcmp(condition_struct.direction,'plot all')
    x_vals = R.directions;
    x_title = 'Movement dir. (°)';
    N_vals = length(R.directions);
    values = zeros(N_vals,1);
    polar = true;

    for i=1:N_vals
        ind = R.speed_by_condition == str2double(condition_struct.speed) & ...
            R.direction_by_condition == R.directions(i) & ...
            R.halfwidth_by_condition == str2double(condition_struct.halfwidth) & ...
            R.contrast_by_condition == str2double(condition_struct.contrast);
        values(i) = val_set(ind);
    end

elseif strcmp(condition_struct.halfwidth,'plot all')
    x_vals = R.halfwidths;
    x_title = 'Half width (µm)';
    N_vals = length(R.halfwidths);
    values = zeros(N_vals,1);

    for i=1:N_vals
        ind = R.speed_by_condition == str2double(condition_struct.speed) & ...
            R.direction_by_condition == str2double(condition_struct.direction) & ...
            R.halfwidth_by_condition == R.halfwidths(i) & ...
            R.contrast_by_condition == str2double(condition_struct.contrast);
        values(i) = val_set(ind);
    end


elseif strcmp(condition_struct.contrast,'plot all')
    x_vals = R.contrasts;
    x_title = 'Contrast';
    N_vals = length(R.contrasts);
    values = zeros(N_vals,1);

    for i=1:N_vals
        ind = R.speed_by_condition == str2double(condition_struct.speed) & ...
            R.direction_by_condition == str2double(condition_struct.direction) & ...
            R.halfwidth_by_condition == str2double(condition_struct.halfwidth) & ...
            R.contrast_by_condition == R.contrasts(i);
        values(i) = val_set(ind);
    end

else
    disp('cannot plot a a single point');
    ind = R.speed_by_condition == str2double(condition_struct.speed) & ...
            R.direction_by_condition == str2double(condition_struct.direction) & ...
            R.halfwidth_by_condition == str2double(condition_struct.halfwidth) & ...
            R.contrast_by_condition == str2double(condition_struct.contrast);
        value = val_set(ind)
        return;
end

if polar
    parent_panel = get(ax,'Parent');
    ax = polaraxes(parent_panel);
    ax.FontUnits = 'points';
    ax.FontSize = 12;
    ax.Units = 'normalized';
    ax.Position = [.1 .1 .8 .8];
end

hold(ax,'on');

if polar
    angles = deg2rad(x_vals);
    angles(end+1) = angles(1);

    vals = values;
    vals(end+1) = vals(1);
    polarplot(ax, angles, vals, ...
        'Color',[0 0 0],...
        'Marker','o',...
        'MarkerFaceColor',[0 0 0],...
        'LineWidth',2);
    legend(ax,{'Cycle avg. peak spike rate (Hz)'},'Location','southwest');
else
    plot(ax, x_vals, values,'Color','k','LineStyle','-','Marker','o','MarkerFaceColor','k','LineWidth',2);
    xlabel(ax, x_title);
    ylabel(ax, 'Cycle avg. peak spike rate (Hz)');
end

hold(ax,'off');