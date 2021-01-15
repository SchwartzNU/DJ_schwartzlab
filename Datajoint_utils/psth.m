function [psth_x, psth_y] = psth(cell_id, epoch_numbers, binSize, baseline_subtract, gauss_win, sliding_win, channel)
if nargin < 7
    channel = 1;
end
if nargin < 6
    sliding_win = 0;
end
if nargin < 5
    gauss_win = 0;
end
if nargin < 4
    baseline_subtract = false;
end
if nargin < 3
    binSize = 10;
end
psth_y = [];

firstEpoch = sl.Epoch & sprintf('cell_id="%s"', cell_id) & sprintf('epoch_number=%d', epoch_numbers(1));
ep_struct = firstEpoch.fetch('*');
sampleRate = ep_struct.sample_rate;
if isfield(ep_struct.protocol_params, 'preTime')
    preTime = ep_struct.protocol_params.preTime;
else
    preTime = 0;
end
if isfield(ep_struct.protocol_params, 'tailTime')
    postTime = ep_struct.protocol_params.tailTime;
else
    postTime = 0;
end
stimTime = ep_struct.protocol_params.stimTime;

Nepochs = length(epoch_numbers);
N_samples = ceil((preTime + stimTime + postTime) / binSize);
total_time_ms = preTime + stimTime + postTime; %ms
psth_x = (0:N_samples-1) * binSize / 1E3 - preTime / 1E3; % units of seconds

allSpikes = [];
for i=1:Nepochs
    thisEpoch = sl.Epoch & sprintf('cell_id="%s"', cell_id) & sprintf('epoch_number=%d', epoch_numbers(i));
    thisSpikeTrain = sl_mutable.SpikeTrain & thisEpoch & sprintf('channel=%d', channel);
    ep_struct = thisEpoch.fetch('*');
    cur_sampleRate = ep_struct.sample_rate;
    if isfield(ep_struct.protocol_params, 'preTime')
        cur_preTime = ep_struct.protocol_params.preTime;
    else
        cur_preTime = 0;
    end
    if isfield(ep_struct.protocol_params, 'tailTime')
        cur_postTime = ep_struct.protocol_params.tailTime;
    else
        cur_postTime = 0;
    end
    cur_stimTime = ep_struct.protocol_params.stimTime;
    
    if cur_sampleRate~=sampleRate || cur_preTime~=preTime || cur_stimTime~=stimTime || cur_postTime~=postTime
        disp('Error: all epochs must have matching pre, stim, post time and sampleRate');
        return;
    end
    
    cur_sp = fetch1(thisSpikeTrain, 'sp');
    cur_sp = 1E3 * cur_sp ./ sampleRate; %now in units of ms, starting at zero
    allSpikes = [allSpikes cur_sp];
end

disp([num2str(length(allSpikes)) ' spikes found']);

bins = 0:binSize:total_time_ms;

spCount = histcounts(allSpikes,bins);
if gauss_win > 0
    w = gausswin(gauss_win);
    w = w / sum(w); %normalize correctly
    spCount = conv(spCount,w,'same');
elseif sliding_win > 0
    spCount = smooth(spCount,sliding_win);
end

if isempty(spCount)
    spCount = zeros(1,length(bins));
end

%convert to Hz
psth_y = 1E3 * spCount ./ (Nepochs * binSize);

if baseline_subtract
    baseline = mean(psth_y(psth_x < 0));
    psth_y = psth_y - baseline;
end
