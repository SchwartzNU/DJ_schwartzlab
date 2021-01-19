function R = spikesInMovingBarEpoch(epoch, pipeline, P)
R = []; %will be struct. error if isempty
sp_train = sl_mutable.SpikeTrain & epoch;
ep_struct = fetch(epoch,'*');
N_trains = sp_train.count;
if N_trains == 0
    disp(['spikesInMovingBarEpoch failed to get spikes: ' ep_struct.cell_id ': epoch ' num2str(ep_struct.epoch_number)]);
    return;
elseif N_trains > 1
    disp(['spikesInMovingBarEpoch duplicate spike train: ' ep_struct.cell_id ': epoch ' num2str(ep_struct.epoch_number)]);
    return;
end

sp = fetch1(sp_train, 'sp');

%get all the params we need
try 
    stimTime = ep_struct.protocol_params.stimTime;
    %some old MB epochs do not have preTime and tailTime - they were fixed at 250 ms in the protocol
    if isfield(ep_struct.protocol_params, 'preTime')
        preTime = ep_struct.protocol_params.preTime;
        tailTime = ep_struct.protocol_params.tailTime;
    else
        preTime = 250;
        tailTime = 250;
    end
    sample_rate = ep_struct.sample_rate;
    barSpeed = ep_struct.protocol_params.barSpeed; %microns per second
    distance = ep_struct.protocol_params.distance; %microns per second
    barLength = ep_struct.protocol_params.barLength; %microns
catch
    fprintf('spikesInMovingBarEpoch failed for cell %s, epoch %d. Unable to get a needed epocch parameter.\n', ...
        ep_struct.cell_id, ep_struct.epoch_number);    
    return;
end

screenMidPoint = distance/2;
barMidPoint = barLength/2;
timeToMidPoint = 1E3 * (screenMidPoint+barMidPoint) / barSpeed; %ms

sp = 1E3 * sp / sample_rate - preTime; %convert to ms to match pre, stim, tailTime and make stim onset = 0
R.preCount = length(find(sp<=0));
R.stimCount = length(find(sp>0 & sp<=stimTime));
R.tailCount = length(find(sp>stimTime));

R.stimCount_ON = length(find(sp>0 & sp<=timeToMidPoint));
R.stimCount_OFF = length(find(sp>timeToMidPoint & sp<=stimTime));
R.ON_dur = timeToMidPoint / 1E3;
R.OFF_dur = (stimTime - timeToMidPoint) / 1E3;
R.ON_OFF_index = (R.stimCount_ON - R.stimCount_OFF) / (R.stimCount_ON + R.stimCount_OFF);

%durations in seconds
R.preDur = preTime/1E3;
R.stimDur = stimTime/1E3;
R.tailDur = tailTime/1E3;



