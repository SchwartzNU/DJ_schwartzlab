function [] = reloadCellDataFile(cell_id)
%needs to be done by an admin: sl_user account
thisEntry = sl.SymphonyRecordedCell & sprintf('cell_id="%s"', cell_id);
if ~thisEntry.exists
    fprintf('Cell %s not found in database\n', cell_id);
end

del(thisEntry);
populate(sl.SymphonyRecordedCell, sprintf('cell_id="%s"', cell_id));