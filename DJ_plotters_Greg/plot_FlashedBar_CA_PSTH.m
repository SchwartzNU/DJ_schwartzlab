function required_fields = plot_FlashedBar_CA_PSTH(R,ax)
if nargin < 1
    required_fields = {'psth_by_angle', 'bar_angles', 'psth_x'};
    return;
end

colormap(ax,'parula');
imagesc(ax,R.psth_by_angle);
x_vals = R.psth_x;
L = length(x_vals);
N_ticks = 5;
X_ticks = linspace(x_vals(1), x_vals(end), N_ticks);
X_ticks_locations = linspace(1, L, N_ticks);
Y_ticks = R.bar_angles;
Y_ticks_locations = 1:length(R.bar_angles);

set(ax, 'XtickLabel', X_ticks);
set(ax, 'Xtick', X_ticks_locations);
set(ax, 'YtickLabel', Y_ticks);
set(ax, 'Ytick', Y_ticks_locations);

xlabel(ax, 'Time (s)')
ylabel(ax, 'Bar angle (degrees)');
axis(ax,'tight');
cbar = colorbar(ax);
cbar.Label.String = 'Firing rate (Hz)';