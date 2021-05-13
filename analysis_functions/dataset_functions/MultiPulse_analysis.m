function K = multiPulseAnalysis(dataset, pipeline, P)
%results resistance and capacitance of each cell
%also plots F-I curve (rate vs. current)
%inputs dataset from query

%retrieve from dataset what I need
dataset_struct = fetch(dataset,'*'); %Do I need this? Is dataset already a struct?

%Make sure epochs from Multi Pulse
if ~strcmp(dataset_struct.dataset_protocol_name, 'Multi Pulse')
    disp('Error: SMS_spike_analysis designed for datasets of type: Spots Multi Size');
    return;
end

epoch_ids = dataset_struct.epoch_ids;
N_epochs = length(epoch_ids);

%set up search key for finding results
%looking for results from spikeWaveformAnalysis and my pipeline
result_key.pipeline_name = pipeline;
result_key.epoch_func_name = 'spikeWaveformAnalysis';

%get all neccessary results and epoch parameters
current = zeros(N_epochs,1);
computedVals = struct;
computedVals.spikeRatePre = zeros(N_epochs,1);
computedVals.spikeRateStim = zeros(N_epochs,1);
computedVals.spikeRatePost = zeros(N_epochs,1);
computedVals.spikeRateResponse = zeros(N_epochs,1); %stim and post
computedVals.spikeRateFull = zeros(N_epochs,1); %pre, stim, and post

for i=1:N_epochs
    %use query to get epoch from epoch table
    ep = sl.Epoch & dataset & sprintf('epoch_number=%d', epoch_ids(i));
    %check for missing epoch
    if ~ep.exists
        fprintf('Missing epoch %d', epoch_ids(i));
        R = []; %what does this do?
        return;
    end
    
    %fetch all attributes from each epoch
    ep_struct = ep.fetch('*');
    
    [timeAxis, rawVoltageTrace] = epochRawData(ep_struct.cell_id, ep_struct.epoch_number);

    %Merge this epoch's attributes with the search key
    %Now 'key' will allow you to look for EpochResults from this epoch with
    %func_name = spikeWaveformAnalysis and 
    %pipeline = current pipeline
    key = mergeStruct(ep_struct, result_key);
    
    %get stored result, stored in 'result' attribute
    ep_result = getStoredResult('Epoch', key);
    
    %fetch it
    ep_result_R = fetch1('result');
    
    computedVals.spikeRatePre(i) = ep_result_R.preCount / ep_result_R.preDur;
    computedVals.spikeRateStim(i) = ep_result_R.stimCount / ep_result_R.stimDur;
    computedVals.spikeRatePost(i) = ep_result_R.tailCount / ep_result_R.tailDur;
    computedVals.spikeRateResponse(i) = (ep_result_R.stimCount + ep_result_R.tailCount) / (ep_result_R.stimDur + ep_result_R.tailDur);
    totalTime = ep_result_R.preDur + ep_result_R.stimDur + ep_result_R.tailDur;
    totalCount = ep_result_R.preCount + ep_result_R.stimCount + ep_result_R.tailCount;
    computedVals.spikeRateFull(i) = totalCount / totalTime;
    %get current from epoch result
    current(i) = ep_result_R.current;
    
    %Get resistance
    if current(i) < 0
        %access voltage at pre time
        %access voltage at stim time
        %subtract voltage at stim time - voltage at pre time
        %divide by current step (adjust for units)
    end
    
end

%see all protocol parameters and which ones are changing each epoch
[protocol_params, changing_fields] = getExampleProtocolParametersForEpochInDataset(cell_id, dataset_name);


%plan
%F-I Curve
%Capacitance Finder

%save all in variable
K.current = current;
