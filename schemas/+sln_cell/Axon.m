%{
#Entity of RGC axon in the brain, one axon could be associated with multiple axon image. 
axon_id: int unsigned AUTO_INCREMENT
---
->[nullable] sln_cell.Cell
 (brain_region)->[nullable]sln_animal.BrainArea
side: enum('Ipsilateral', 'Contralateral', 'Unknown')

%}
classdef Axon < dj.Manual
    methods (Static)
        function axon_id = add_axon(brain_region, side, cell_unid)
            arguments
                brain_region 
                side 
                cell_unid = NaN
            end
            try
                C = dj.conn;
                C.startTransaction;
                key.brain_region = brain_region;

                key.side = side;

                if (~isnan(cell_unid))
                    key.cell_unid = cell_unid;
                end
                insert(sln_cell.Axon, key);
                ids = fetch(sln_cell.Axon, 'axon_id');
                axon_id = max([ids.axon_id]);
                fprintf('New axon added: %d\n', axon_id);
            catch ME
                rethrow (ME)
            end
        end
    end
end