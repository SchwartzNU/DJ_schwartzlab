function required_fields = plot_SMS_PSTH(R,ax)
if nargin < 1
    required_fields = {'psth_x', 'spot_sizes', 'sms_psth'};
    return;
end

hold(ax,'on');
x_vals = R.psth_x;
y_vals = R.spot_sizes;
p_surf = pcolor(ax, x_vals, y_vals, R.sms_psth);
set(p_surf, 'EdgeColor','none');
colormap(ax,'parula');
xlabel(ax, 'Time (s)')
ylabel(ax, 'Spot size (µm)');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
axis(ax,'tight');
cbar = colorbar(ax);
cbar.Label.String = 'Firing rate (Hz)';
hold(ax,'off');