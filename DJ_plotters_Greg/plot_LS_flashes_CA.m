function required_fields = plot_LS_flashes_CA(R,ax)
if nargin < 1
    required_fields = {'psth_x', 'psth_y', 'pre_time_ms'};
    return;
end

hold(ax,'on');
x_vals = R.psth_x - R.pre_time_ms/1E3;
y_vals = R.psth_y;
bar(ax,x_vals,y_vals,'FaceColor','k','BarWidth',1);
xlabel(ax, 'Time (s)')
ylabel(ax, 'Firing rate (Hz)');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
axis(ax,'tight');
hold(ax,'off');