%{
#association table showing RGC axons in the brain and cooresponding axonal images
->sln_cell.Axon
->sln_image.AxonInBrain
---
%}
classdef AxonImageAssociation< dj.Manual
    methods (Static)
        function add_axon_img_asso(axon_arry, img_array)
            if (isscalar(axon_arry) && isscalar(img_array))
                %inserting axon and image are single number
                try
                    %sanity check
                    key.axon_id = axon_arry;
                    key.image_id = img_array;
                    q = fetch(sln_image.AxonImageAssociation & key);
                    if (~isempty(q))
                        fprintf('Axon %d -- image %d already linked!\n', axon_arry, img_array);
                        return;
                    else
                        C = dj.conn;
                        C.startTransaction;
                        insert(sln_image.AxonImageAssociation, key);
                        disp(key);
                        fprintf('Inserted!\n');
                        C.commitTransaction;
                    end

                catch ME
                    rethrow (ME);
                end
            else
                if(xor(isscalar(axon_arry), isscalar(img_array)))
                    error('Two input must have same length!\n');
                end

                if(numel(axon_arry)~=numel(img_array))
                    error('Two input must have same length!\n');
                end

                try
                    C = dj.conn;
                    C.startTransaction;
                    %insert array of image id and axon id
                    for i = 1:numel(axon_arry)
                        key.axon_id = axon_arry(i);
                        key.image_id = img_array(i);
                        q = fetch(sln_image.AxonImageAssociation & key);
                        if (~isempty(q))
                            fprintf('Axon %d -- image %d already linked!\n', key.axon_id, key.image_id);
                            continue;
                        end

                        insert(sln_image.AxonImageAssociation, key);
                        fprintf('Inserted axon %d with image %d!\n', key.axon_id, key.image_id);
                    end
                    C.commitTransaction;

                catch ME
                    rethrow (ME);
                end
           end
        end
    end
end