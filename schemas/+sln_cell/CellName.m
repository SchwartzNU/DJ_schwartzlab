function q = CellName()

q = proj(sln_symphony.ExperimentCell, ...
            'concat(file_name, "c", cell_number)->cell_name');  j