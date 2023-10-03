function required_fields = plot_DriftingGratings_SpeedTuning_cycleAvgMeanPos(R,ax)
if nargin < 1
    required_fields = {'mean_cycle_avg_peak_pos','speeds'};
    return;
end

plot(ax,R.speeds,R.mean_cycle_avg_peak_pos,'kx-','linewidth',2);
xlabel(ax,'Speed (µm/s)');
ylabel(ax,'Cycle avg. mean peak pos. (mV)');
set(ax,'Xm TickMode','auto');
set(ax,'YTickMode','auto');
set(ax,'XTickLabelMode','auto'); 
set(ax,'YTickLabelMode','auto');