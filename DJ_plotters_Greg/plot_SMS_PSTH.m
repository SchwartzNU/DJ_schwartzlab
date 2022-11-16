function plot_SMS_PSTH(R,ax)
%set(ax, 'XLimM',[0 inf]);
%hold(ax,'on');
cmap = colormap(ax,'parula');
imagesc(ax,flipud(R.sms_psth));
hold(ax,'on');
x_vals = R.psth_x;
L = length(x_vals);
N_ticks = 5;
X_ticks = linspace(x_vals(1), x_vals(end), N_ticks);
X_ticks_locations = linspace(1, L, N_ticks);
Y_ticks = flipud(R.spot_sizes);
Y_ticks_locations = 1:length(R.spot_sizes);

set(ax, 'XtickLabel', X_ticks);
set(ax, 'Xtick', X_ticks_locations);
set(ax, 'YtickLabel', Y_ticks);
set(ax, 'Ytick', Y_ticks_locations);
set(ax, 'YDir','reverse')

xlabel(ax, 'Time (s)')
ylabel(ax, 'Spot size (µm)');
axis(ax,'tight');
cbar = colorbar(ax);
cbar.Label.String = 'Firing rate (Hz)';
hold(ax,'off');