function q = BrainCellName()

q = proj(sln_symphony.ExperimentBrainCell, ...
            'concat(file_name, "c", cell_number)->cell_name');