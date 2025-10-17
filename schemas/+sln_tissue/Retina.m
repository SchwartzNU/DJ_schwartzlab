%{
#Retina as tissue
-> sln_tissue.Tissue
-> sln_animal.Eye
---
%}

classdef Retina < dj.Manual
 methods (Static)
     function tissue_id = add_new_retina(Username, eyeside, animal_id, comment)
         arguments
             Username 
             eyeside 
             animal_id 
             comment = NaN
         end
         try
             key.owner = Username;
             if(~isnan(comment))
                 key.tissue_info = convertStringsToChars(comment);
             end

             C = dj.conn;
             C.startTransaction;
             insert(sln_tissue.Tissue, key);

             qstruct.owner = Username;
             result = fetch(sln_tissue.Tissue&qstruct, 'tissue_id');
             new_to_old = sort([result.tissue_id],'descend');
             key.tissue_id = new_to_old(1);
             
             if (isstring(animal_id))

                key.animal_id = str2double( animal_id);
             else
                 key.animal_id = animal_id;
             end

            key.side = eyeside;
            key = rmfield(key, 'owner');

            insert(sln_tissue.Retina, key);
            C.commitTransaction;
            disp(key);
            fprintf('Successfully inserted retina tissue!');
            tissue_id = key.tissue_id;

         catch ME
             rethrow (ME);
         end
     end
 end
end