function plot_SMS_PSTH(R,ax)
%set(ax, 'XLimM',[0 inf]);
%hold(ax,'on');
%imagesc(ax,flipud(R.sms_psth));
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