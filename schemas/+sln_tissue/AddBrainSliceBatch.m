function slicebatchid = AddBrainSliceBatch(keys)
checkanimal = "animal_id = " + keys.animal_id;
query = sln_tissue.BrainSliceBatch & checkanimal;
%check if the batch already exisits in datajoint
if exists(query)
    fprintf('Brain slice batch already exits, function exiting...');
    query
    return;
end
%try insert, first into sln_tissue.Tissue to get and id
try
    C = dj.conn;
    C.startTransaction;
    tissuestruct.owner = keys.owner;
    if isfield(keys, tissue_info)
        tissuestruct.tissue_info = keys.tissue_info;
    end
    %create an entry in sln_tissue.Tissue
    insert(sln_tissue.Tissue, tissuestruct);

    %now get the newest id and insert into the BrainSliceBatch
    %table
    newTissueid  = fetch1(sln_tissue.Tissue & tissuestruct, tissue_id);
    keys.tissue_id = newTissueid;
    insert(sln_tissue.BrainSliceBatch, keys);

    C.commitTransaction;
catch ME
    C.cancelTransaction;
    rethrow(ME)
end
end
