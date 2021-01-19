function tableData = plotEpochRawData(R,entry,ax)
tableData = [];
[timeAxis, data] = epochRawData(entry.cell_id, entry.epoch_number);
plot(ax, timeAxis, data);
xlabel(ax,'Time (s)');
%look for spike data
spResult = sl.SpikeTrain & entry;
if spResult.count == 1
    sp = spResult.fetch1('sp');
%     dt = timeAxis(2) - timeAxis(1);
%     preTime_s = timeAxis(1);
%sp = sp * dt - preTime_s;
    hold(ax,'on');
    scatter(ax, timeAxis(sp), data(sp), 'rx');
    hold(ax,'off');
end


