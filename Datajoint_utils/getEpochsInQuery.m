function [ep_count, ep_in_datasets] = getEpochsInQuery(query)
ep_q = sl.Epoch & query;
dataset_structs = query.fetch('epoch_ids');
fullRestrictionStruct = [];
for i=1:length(dataset_structs)
    epid = dataset_structs(i).epoch_ids;
    Nep = length(epid);
    thisRestrictionStruct = repmat(dataset_structs(i), Nep, 1);
    for n=1:Nep
        thisRestrictionStruct(n).epoch_number = epid(n);
    end
    fullRestrictionStruct = [fullRestrictionStruct; thisRestrictionStruct];
end
ep_in_datasets = ep_q & fullRestrictionStruct;
ep_count = ep_in_datasets.count;
