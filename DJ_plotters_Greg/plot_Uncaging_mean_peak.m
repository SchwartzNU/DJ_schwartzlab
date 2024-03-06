function required_fields = plot_Uncaging_mean_peak(R,ax)
if nargin < 1
    required_fields = {'peak_resp'};
    return;
end

%set(ax, 'XLim',[0 inf]);
N_spots = length(R.trial_peak_resp_mean);
plot(ax, 1:N_spots, R.peak_resp,...
    'Color',[0 0 0], ...
    'LineWidth',2);
hold(ax,'on');
scatter(ax, 1:N_spots, R.peak_resp,50,'ko',...
    'filled');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
xlabel(ax, 'Uncaging spot number')
ylabel(ax, 'Peak response (mV)');
hold(ax,'off');
