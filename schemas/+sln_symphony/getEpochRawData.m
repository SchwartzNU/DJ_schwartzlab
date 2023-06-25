function [timeAxis, data, data_mean, data_sd] = getEpochRawData(ep, channel_name)
if nargin < 2
    channel_name = 'Amp1';
end
%ep is the query containing all the epochs
ep = sln_symphony.ExperimentEpochChannel * ...
    sln_symphony.ExperimentChannel * ...
    sln_symphony.ExperimentEpochBlock * ...
    aka.Epoch & proj(ep) & ...
    sprintf('channel_name = "%s"', channel_name);

Nepochs = length(ep.count);
if Nepochs == 0
    disp('no epochs in query');
    return
end

ep_struct = fetch(ep,'*');

if length(unique([ep_struct.sample_rate])) > 1
    disp('cannot average epochs with different sample rates');
    return
end

if length(unique([ep_struct.epoch_duration])) > 1
    disp('cannot average epochs with different durations');
    return
end

sample_rate = ep_struct(1).sample_rate;
protocol_name = sqlProtName2ProtName(ep_struct(1).protocol_name);

block_params = fetch(aka.BlockParams(protocol_name) & ep, '*');

data = cell(Nepochs,1);
T = cell(Nepochs,1);
L = zeros(Nepochs,1);

for i=1:Nepochs
    cur_block_params = block_params(i);
    if isfield(cur_block_params, 'pre_time')
        if ~isnan(cur_block_params.pre_time)
            preTime = cur_block_params.pre_time;
        else
            preTime = 0;
        end
    else
        preTime = 0;
    end

    data{i} = ep_struct(i).raw_data;
    L(i) = length(data{i});   
    T{i} = (0:L(i)-1) ./ sample_rate - preTime / 1E3;
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
    data_sd = zeros(1,L);
end