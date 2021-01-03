function [] = reloadCellDataFile(cell_id)
thisEntry = sl.SymphonyRecordedCell & sprintf('cell_id="%s"', cell_id);
if ~thisEntry.exists
    fprintf('Cell %s not found in database\n', cell_id);
end

del(thisEntry);
populate(sl.SymphonyRecordedCell, sprintf('cell_id="%s"', cell_id));