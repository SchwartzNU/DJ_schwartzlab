function tableData = plotEpochRawData(R,entry,ax)
tableData = [];
[timeAxis, data] = epochRawData(entry.cell_id, entry.epoch_number);
plot(ax, timeAxis, data, 'k');
xlabel(ax,'Time (s)');
%look for spike data
spResult = sl_mutable.SpikeTrain & entry;
if spResult.count == 1
    sp = spResult.fetch1('sp');
    hold(ax,'on');
    scatter(ax, timeAxis(sp), data(sp), 'rx');
    hold(ax,'off');
end


