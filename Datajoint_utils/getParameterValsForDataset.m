function vals = getParameterValsForDataset(dataset, paramName)
epoch_ids = dataset.fetch1('epoch_ids');
N = length(epoch_ids);
vals = zeros(N,1);

for i=1:N
    ep = sl.Epoch & dataset & sprintf('epoch_number=%d',epoch_ids(i));
    ep_struct = ep.fetch('*');
    vals(i) = ep_struct.protocol_params.(paramName);
end