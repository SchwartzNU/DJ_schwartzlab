function required_fields = plot_SMS_VC(R,ax)
if nargin < 1
    required_fields = {'peak_stim_mean', 'spot_sizes', 'peak_stim_sem', ...
        'peak_tail_mean', 'peak_tail_sem'};
    return;
end

set(ax, 'XLim',[0 inf]);
errorbar(ax, R.spot_sizes, R.peak_stim_mean, R.peak_stim_sem,...
    'Color',[0 1 1],...
    'LineWidth',2);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
hold(ax,'on');
xlabel(ax, 'Spot size (microns)')
ylabel(ax, 'Peak response (pA)');
errorbar(ax, R.spot_sizes, R.peak_tail_mean, R.peak_tail_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
legend(ax,{'ON', 'OFF'});
hold(ax,'off');
