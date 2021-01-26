function R = spikesInPreStimPost(epoch, pipeline, P)
R = []; %will be struct. error if isempty
sp_train = sl_mutable.SpikeTrain & epoch;
ep_struct = fetch(epoch,'*');
N_trains = sp_train.count;
if N_trains == 0
    disp(['spikesInPreStimPost failed to get spikes: ' ep_struct.cell_id ': epoch ' num2str(ep_struct.epoch_number)]);
    return;
elseif N_trains > 1
    disp(['spikesInPreStimPost duplicate spike train: ' ep_struct.cell_id ': epoch ' num2str(ep_struct.epoch_number)]);
    return;
end

sp = fetch1(sp_train, 'sp');

%get pre, stim, and tail times in ms
try 
    preTime = ep_struct.protocol_params.preTime;
    stimTime = ep_struct.protocol_params.stimTime;
    tailTime = ep_struct.protocol_params.tailTime;
    sample_rate = ep_struct.sample_rate;
catch
    fprintf('spikesInPreStimPost failed for cell %s, epoch %d. Unable to get preTime, stimTime, or tailTime or sampleRate.\n', ...
        ep_struct.cell_id, ep_struct.epoch_number);    
    return;
end

sp = 1E3 * sp / sample_rate - preTime; %convert to ms to match pre, stim, tailTime and make stim onset = 0
R.preCount = length(find(sp<=0));
R.stimCount = length(find(sp>0 & sp<=stimTime));
R.tailCount = length(find(sp>stimTime));

%durations in seconds
R.preDur = preTime/1E3;
R.stimDur = stimTime/1E3;
R.tailDur = tailTime/1E3;



