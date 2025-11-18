function tableData= plot_opto_single_VC(R,ax)
set(ax, 'XLim', [0, inf]);
time_total = (R.pre_time_ms + R.stim_time_ms + R.tail_time_ms)/1E3;
axis_x = linspace(0, time_total, time_total*R.sample_rate);
plot(axis_x, R.average_trace, 'k');
hold (ax, 'on');
xline(R.pre_time_ms*R.sample_rate/1E3, '-', 'b');
xline((R.pre_time_ms+R.stim_time_ms)*R.sample_rate/1E3, '--', 'b');
ylabel(ax, 'Synpatic current (pA)');
xbale(ax, 'Time(ms)');
tableData.total_Epoch = R.epoch_total;

end