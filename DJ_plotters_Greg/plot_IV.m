function required_fields = plot_IV(R,ax)
if nargin < 1
    required_fields = {'peak_current_by_timeslice_mean', ...
        'hold_voltages', ...
        'peak_current_by_timeslice_sem',...
        'timeslices'};
    return;
end

N_timeslices = size(R.timeslices,1);
slice_names = cell(N_timeslices,1);
hold(ax,'on');
for i=1:N_timeslices
    slice_names{i} = sprintf('%d-%d ms', R.timeslices(i,1), R.timeslices(1,2));
    errorbar(ax, R.hold_voltages, R.peak_current_by_timeslice_mean{i}, R.peak_current_by_timeslice_sem{i},...
        'LineWidth',2);    
end
line(ax,[0 0], get(ax,'Ylim'),'Color','k','linestyle','--');
line(ax, get(ax,'Xlim'),[0 0],'Color','k','linestyle','--');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
xlabel(ax, 'Hold voltage (mV)')
ylabel(ax, 'Peak response (pA)');
legend(ax,slice_names);
hold(ax,'off');
