function required_fields = plot_Uncaging_trial_peak(R,ax)
if nargin < 1
    required_fields = {'trial_peak_resp_mean', 'trial_peak_resp_sem'};
    return;
end

%set(ax, 'XLim',[0 inf]);
N_spots = length(R.trial_peak_resp_mean);
errorbar(ax, 1:N_spots, R.trial_peak_resp_mean, R.trial_peak_resp_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
xlabel(ax, 'Uncaging spot number')
ylabel(ax, 'Peak response (mV)');
