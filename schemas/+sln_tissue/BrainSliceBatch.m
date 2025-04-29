%{
#describe the brain slice 
-> sln_tissue.Tissue
---
->sln_animal.Animal
slicing_orientation: enum('Coronal', 'Saggital', 'Horizontal')
thickness: smallint unsigned
%}

classdef BrainSliceBatch < dj.Manual
methods
    function slicebatchid = addBrainSliceBatch(keys)
        checkanimal = "animal_id = " + keys.animal_id;
        query = sln_tissue.BrainSliceBatch & checkanimal;
        %check if the batch already exisits in datajoint
        if exists(query)
            fprintf('Brain slice batch already exits, function exiting...');
            query
            return;
        end
        %know try inserting
        try
            C = dj.conn;
            C.startTransaction;
            insert(sln_tissue.BrainSliceBatch, keys);
            slicebatchid = fetch1(sln_tissue.BrainSliceBatch, 'tissue_id');
            C.commitTransaction;
        catch ME
            C.cancelTransaction;
            rethrow(ME)
        end
    end
end
end
