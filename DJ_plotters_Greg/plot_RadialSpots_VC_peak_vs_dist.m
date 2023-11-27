function required_fields = plot_RadialSpots_VC_peak_vs_dist(R,ax)
if nargin < 1
    required_fields = {'peak_matrix_mean', 'peak_matrix_sem', ...
        'spot_dist'};
    return;
end

R.peak_matrix_mean(R.peak_matrix_mean==0) = nan;
R.peak_matrix_sem(R.peak_matrix_mean==0) = nan;

errorbar(ax, R.spot_dist, nanmean(R.peak_matrix_mean,1), nanmean(R.peak_matrix_sem,1), ...
    'LineWidth', 2, 'Color','k');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
axis(ax,'auto');
xlabel(ax,'Spot distance (µm)');
ylabel(ax, 'Peak response (pA)');