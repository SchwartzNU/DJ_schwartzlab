function [empty_cells] = findCellsWithNoEpochs()
empty_cells = {};
allCells = sl.SymphonyRecordedCell;
allCells_primary = allCells.fetch;
for i=1:allCells.count
   ep = sl.Epoch & allCells_primary(i);
   if ep.count==0
       empty_cells = [empty_cells; allCells_primary(i).cell_id];
   end
end