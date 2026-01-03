%{
#Entity of RGC axon in the brain, one axon could be associated with multiple axon image. 
axon_id: int unsigned AUTO_INCREMENT
---
->sln_animal.Animal
(brain_region)->[nullable]sln_animal.BrainArea
side: enum('Ipsilateral', 'Contralateral', 'Unknown')
%}
classdef Axon < dj.Manual
    methods (Static)
        function axon_id = add_axon(brain_region, side, animal)
            arguments
                brain_region 
                side 
                animal
            end
            try
                C = dj.conn;
                C.startTransaction;
                key.brain_region = brain_region;
                key.animal_id = animal;
                key.side = side;

                insert(sln_cell.Axon, key);
                ids = fetch(sln_cell.Axon&key, 'axon_id');
                axon_id = max([ids.axon_id]);
                fprintf('New axon added: %d\n', axon_id);
            catch ME
                rethrow (ME)
            end
        end
    end
end