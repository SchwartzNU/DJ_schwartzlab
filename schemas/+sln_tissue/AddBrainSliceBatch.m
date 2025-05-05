function slicebatchid = AddBrainSliceBatch(keys)
checkanimal = "animal_id = " + keys.animal_id;
query = sln_tissue.BrainSliceBatch & checkanimal;
%check if the batch already exisits in datajoint
if exists(query)
    fprintf('Brain slice batch already exits, function exiting...');
    query
    slicebatchid  = -1;
    return;
end
%try insert, first into sln_tissue.Tissue to get and id
try
    C = dj.conn;
    C.startTransaction;
    tissuestruct.owner = keys.owner;
    if isfield(keys, 'tissue_info')
        tissuestruct.tissue_info = keys.tissue_info;
        keys = rmfield(keys, 'tissue_info');
    end
    %create an entry in sln_tissue.Tissue
    insert(sln_tissue.Tissue, tissuestruct);
    C.commitTransaction;

    %now get the newest id and insert into the BrainSliceBatch
    %table
    
    allTissueIds  = fetchn(sln_tissue.BrainSliceBatch, 'tissue_id');
    keys.tissue_id = max(allTissueIds);

    %delete the fields that are not in the BrainSliceBatch table
    keys = rmfield(keys, 'owner');
    
    insert(sln_tissue.BrainSliceBatch, keys);

    C.commitTransaction;
catch ME
    deletestring = append('tissue_id = ', int2str(keys.tissue_id));
    del (sln_tissue.Tissue & deletestring);
    C.cancelTransaction;
    rethrow(ME)
end
end
