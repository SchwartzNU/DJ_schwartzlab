function required_fields = plot_DriftingGratings_SpeedTuning_cycleAvgMeanNeg(R,ax)
if nargin < 1
    required_fields = {'mean_cycle_avg_peak_neg','speeds'};
    return;
end

plot(ax,R.speeds,R.mean_cycle_avg_peak_neg,'kx-','linewidth',2);
xlabel(ax,'Speed (µm/s)');
ylabel(ax,'Cycle avg. mean peak negative (mV)');
set(ax,'XTickMode','auto');
set(ax,'YTickMode','auto');
set(ax,'XTickLabelMode','auto'); 
set(ax,'YTickLabelMode','auto');