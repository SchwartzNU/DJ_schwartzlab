function [empty_cells] = findCellsWithNoDatasets()
empty_cells = {};
allCells = sl.SymphonyRecordedCell;
allCells_primary = allCells.fetch;
for i=1:allCells.count
   datasets = sl.Dataset & allCells_primary(i);
   if datasets.count==0
       empty_cells = [empty_cells; allCells_primary(i).cell_id];
   end
end