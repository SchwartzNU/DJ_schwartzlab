function required_fields = plot_RadialSpots_spikes_vs_dist(R,ax)
if nargin < 1
    required_fields = {'spike_count_matrix_mean', 'spike_count_matrix_sem', ...
        'spot_dist'};
    return;
end

R.spike_count_matrix_sem(R.spike_count_matrix_mean==0, 1) = nan;
R.spike_count_matrix_mean(R.spike_count_matrix_mean==0, 1) = nan;

errorbar(ax, R.spot_dist, nanmean(R.spike_count_matrix_mean,1), nanmean(R.spike_count_matrix_sem,1), ...
    'LineWidth', 2, 'Color','k');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
axis(ax,'auto');
xlabel(ax,'Spot distance (µm)');
ylabel(ax, 'Spikes');