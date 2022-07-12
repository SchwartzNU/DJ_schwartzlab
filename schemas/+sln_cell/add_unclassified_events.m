untyped_cells = sln_cell.Cell - (sln_cell.CellEvent * sln_cell.AssignType);
if untyped_cells.exists
    cell_unid = fetchn(untyped_cells,'cell_unid');
    for i=1:untyped_cells.count
        key.cell_class = 'other';
        key.cell_type = 'unclassified';
        key.cell_unid = cell_unid(i);
        key.user_name = 'Unknown';
        sln_cell.add_event(key,'AssignType');
    end
end