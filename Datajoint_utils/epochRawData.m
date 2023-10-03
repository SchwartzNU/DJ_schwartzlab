function [timeAxis, data, data_mean, data_sd] = epochRawData(cell_id, epoch_numbers, channel)
if nargin < 3
    channel = 1;
end

Nepochs = length(epoch_numbers);
data = cell(Nepochs,1);
T = cell(Nepochs,1);
L = zeros(Nepochs,1);
firstEpoch = sl.Epoch & sprintf('cell_id="%s"', cell_id) & sprintf('epoch_number=%d', epoch_numbers(1));
fname = [getenv('raw_data_folder'), firstEpoch.fetch1('raw_data_filename'), '.h5'];

for i=1:Nepochs
    thisEpoch = sl.Epoch & sprintf('cell_id="%s"', cell_id) & sprintf('epoch_number=%d', epoch_numbers(i));
    ep_struct = thisEpoch.fetch('*');
    sampleRate = ep_struct.sample_rate;
    if isfield(ep_struct.protocol_params, 'preTime')
        preTime = ep_struct.protocol_params.preTime;
    else
        preTime = 0;
    end
    if channel==2
        D = h5read(fname, ep_struct.data_link2);
    else
        D = h5read(fname, ep_struct.data_link);
    end
    if isstruct(D)
        data{i} = D.quantity';
    else
        data{i} = D';
    end
    L(i) = length(data{i});   
    T{i} = (0:L(i)-1) ./ sampleRate - preTime / 1E3;
end

if Nepochs>1
    if all(L==L(1))
        timeAxis = T{1};
        data = cell2mat(data);
        data_mean = mean(data,1);
        data_sd = std(data,[],1);
    else
        timeAxis = T;        
    end
else
    timeAxis = T{1};  
    data = data{1};
    data_mean = data;
    data_sd = zeros(L,1);
end