function required_fields = plot_DriftingGratings_SpeedTuning_cycleAvgMax(R,ax)
if nargin < 1
    required_fields = {'max_cycle_avg_amplitude','speeds'};
    return;
end

plot(ax,R.speeds,R.max_cycle_avg_amplitude,'kx-','linewidth',2);
xlabel(ax,'Speed (µm/s)');
ylabel(ax,'Cycle avg. max amplitude (mV)');
