function required_fields = plot_FIcurve(R,ax)
if nargin < 1
    required_fields = {'fr_per_current_mean', 'fr_per_current_sem', 'inj_current'};
    return;
end

set(ax, 'XLim',[0 inf]);
errorbar(ax, R.inj_current, R.fr_per_current_mean, R.fr_per_current_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
hold(ax,'on');
xlabel(ax, 'Injected current (pA)')
ylabel(ax, 'Firing rate (Hz)');
hold(ax,'off');
