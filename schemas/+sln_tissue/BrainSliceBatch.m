%{
#describe the brain slice 
-> sln_tissue.Tissue
---
slicing_orientation: enum('Coronal', 'Saggital', 'Horizontal')
thickness: smallint unsigned
->sln_animal.Animal
%}

classdef BrainSliceBatch < dj.Manual
    methods(Static)
        function tissue_id = add_BrainSliceBatch(owner, slice_ori, thickness, animal_id, tissue_info)
            arguments
                owner 
                slice_ori 
                thickness 
                animal_id 
                tissue_info = NaN;
            end
            %construct the inserting function
            
            key.slicing_orientation = slice_ori;
            key.thickness = thickness;
            key.animal_id = animal_id;

            %test if this tissue exisits
            query = append('animal_id = ', int2str(animal_id));
            try
                query = sln_tissue.BrainSliceBatch & query;
                if (exists(query))
                    error('This batch of brain slice already exists!');
                end
                tissue.owner = owner;
                if (~isnan(tissue_info))
                    tissue.tissue_info = tissue_info;
                end
                %start inserting....
                C = dj.conn;
                C.startTransaction;
                insert(sln_tissue.Tissue, tissue);
                tissueids = fetchn(sln_tissue.Tissue, 'tissue_id');

                key.tissue_id = max(tissueids);
                insert(sln_tissue.BrainSliceBatch, key);
                C.commitTransaction;

                fprintf('Inserting success! New brain slice batch: \n');
                disp(key);

            catch ME
                 C.cancelTransaction;
                rethrow(ME);                
            end
        end
    end
end
