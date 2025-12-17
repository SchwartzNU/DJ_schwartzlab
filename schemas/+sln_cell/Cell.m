%{
# A cell from an animal
cell_unid                   : int unsigned AUTO_INCREMENT   # 
---
-> sln_animal.Animal
-> [nullable, unique] sln_symphony.ExperimentCell
%}
classdef Cell < dj.Manual
    methods(Static)
        %this function currently works for cells NOT related to electrophsiology experiment
        function cell_id = insert_get_id(animal)
            cell.animal_id = animal;
            insert(sln_cell.Cell, cell);

            %now we have to query the cell out....
            cells = fetch(sln_cell.Cell & cell);
            %usually the newest one
            sorted_ids = sort([cells.cell_unid], 'descend');
            cell_id = sorted_ids(1);
            fprintf('Added new cell: %d\n', cell_id);
        end
    end
end
