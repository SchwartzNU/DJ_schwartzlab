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
        function axon_id = add_axon(key)
            try
                C = dj.conn;
                C.startTransaction;
                insert(sln_cell.Axon, key);
                ids = fetch(sln_cell.Axon, 'axon_id');
                axon_id = max([ids.axon_id]);
            catch ME
                rethrow (ME)
            end
        end
    end
end