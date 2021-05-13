function recreateSchema

%%drop everything
safemode = dj.config('safemode');
dj.config('safemode', false);
for table = sl_zach.getSchema().tableNames.keys
  drop(feval(table));
end
dj.config('safemode',safemode);


% %MeasuredCell - moves the experimenter from SymphonyRecordedCell to MeasuredCell
% sl_zach.MeasuredCell().insert(fetch(sl.MeasuredCell * sl.SymphonyRecordedCell,'experimenter'));

% %SymphonyRecordedCell - subtracts experimenter
% sl_zach.SymphonyRecordedCell().insert(fetch(sl.SymphonyRecordedCell, 'position_x','position_y','number_of_epochs','online_label','tags','recording_date','rig_name'));



end