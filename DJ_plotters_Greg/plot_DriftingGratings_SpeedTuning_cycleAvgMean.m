function required_fields = plot_DriftingGratings_SpeedTuning_cycleAvgMean(R,ax)
if nargin < 1
    required_fields = {'mean_cycle_avg_amplitude','speeds'};
    return;
end

plot(ax,R.speeds,R.mean_cycle_avg_amplitude,'kx-','linewidth',2);
xlabel(ax,'Speed (µm/s)');
ylabel(ax,'Cycle avg. mean amplitude (mV)');
set(ax,'XTickMode','auto');
set(ax,'YTickMode','auto');
set(ax,'XTickLabelMode','auto'); 
set(ax,'YTickLabelMode','auto');