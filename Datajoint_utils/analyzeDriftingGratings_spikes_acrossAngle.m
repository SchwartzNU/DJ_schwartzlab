function R = analyzeDriftingGratings_spikes_acrossAngle(pipeline, dataset_struct, epoch_ids)
R = [];
N_epochs = length(epoch_ids);

gratingAngle = zeros(N_epochs, 1);

%get all neccessary results and epoch parameters
computedVals = struct;
computedVals.spikeRate = zeros(N_epochs,1);

result_key.pipeline_name = pipeline;
result_key.epoch_func_name = 'spikesInIntervals';

for i=1:N_epochs
    ep = sl.Epoch & dataset_struct & sprintf('epoch_number=%d',epoch_ids(i));
    if ~ep.exists
        fprintf('Missing epoch %d', epoch_ids(i)); 
        R = [];
        return;
    end
    
    ep_struct = ep.fetch('*');
    gratingAngle(i) = round(ep_struct.protocol_params.gratingAngle);
        
    ep_result = sl.EpochResult & ep & result_key;
    if ep_result.count>1
        fprintf('Duplicate result for epoch %d', epoch_ids(i));
        R = [];
        return        
    end
    if ep_result.count ~= 1
        fprintf('analyzeDriftingGratings_spikes_acrossAngle: error loading epoch results from %s for epoch %d \n', ...
            result_key.epoch_func_name, ep_struct.epoch_number);
    end
    ep_result_R = ep_result.fetch1('result');
    computedVals.spikeRate(i) = ep_result_R.stim_0toInf / ep_result_R.stim_0toInf_dur;
    
end

outputStruct = distributeAndOrder(gratingAngle, computedVals);
outputStruct = renameStructField(outputStruct, 'keyVals', 'gratingAngle');
outputStruct = renameStructField(outputStruct, 'key_N', 'Nepochs');

L = length(outputStruct.gratingAngle);
psth_y = cell(L,1);
for i=1:L
   curEpochs = epoch_ids(logical(outputStruct.key_ind(i,:)));
   [psth_x, psth_y{i}] = psth(dataset_struct.cell_id, curEpochs);
   
   cur_psth = psth_y{i};
   %analyze each psth
   ep = sl.Epoch & dataset_struct & sprintf('epoch_number=%d',curEpochs(1));
   ep_params = ep.fetch1('protocol_params');
   sampleRate = ep.fetch1('sample_rate');
   binWidth = 10; %ms
   %get bins
   samplesPerMS = sampleRate/1E3;
   samplesPerBin = binWidth*samplesPerMS;
   
   freq = ep_params.temporalFreq; %Hz
   startDelayBins = floor(ep_params.movementDelay / binWidth);
   cyclePts = floor(sampleRate/samplesPerBin/freq);
   numCycles = floor((length(cur_psth) - startDelayBins) / cyclePts);
   
   % Get the average cycle.
   cycles = zeros(numCycles, cyclePts);
   for j = 1 : numCycles
       index = startDelayBins + round(((j-1)*cyclePts + (1 : floor(cyclePts))));
       cycles(j,:) =  cur_psth(index);
   end
   % Take the mean, skipping first cycle
   avgCycle = mean(cycles(2:end, :),1);
   outputStruct.cycleAvgPSTH_y{i} = avgCycle;
   outputStruct.cycleAvgPSTH_x = psth_x(1:length(avgCycle));
   % Do the FFT.
   ft = fft(avgCycle);
   % figure(10)
   % subplot(3,1,1)
   % plot(psth)
   % subplot(3,1,2)
   % plot(avgCycle)
   % subplot(3,1,3)
   % plot(abs(ft))
   
   % Pull out the F1 and F2 amplitudes.
   outputStruct.F0amplitude(i) = abs(ft(1))/length(ft);
   outputStruct.F1amplitude(i) = abs(ft(2))/length(ft)*2;
   outputStruct.F2amplitude(i) = abs(ft(3))/length(ft)*2;
   %deal with 0/0
   F2overF1 = abs(ft(3))/abs(ft(2));
   if isnan(F2overF1)
       F2overF1 = 0;
   end
   outputStruct.F2overF1(i) = F2overF1;
   
   %Adam 2/13/17
   outputStruct.cycleAvgPeakFR(i) = max(avgCycle);
end

R = outputStruct;

