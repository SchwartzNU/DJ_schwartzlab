function [spikes_leading, spikes_trailing] = spikes_in_mb_epoch(epoch, pre_time, stim_time, bar_speed, bar_distance, bar_length)
sp_train = sln_symphony.SpikeTrain & epoch;

if ~sp_train.exists %no spike train found
    disp('Spike train is missing');
    spikes_leading = nan;
    spikes_trailing = nan;
    return;
end

sp = fetch1(sp_train, 'spike_indices');
sample_rate = fetch1(sln_symphony.ExperimentChannel & epoch, 'sample_rate');

screenMidPoint = bar_distance/2;
barMidPoint = bar_length/2;
timeToMidPoint = 1E3 * (screenMidPoint+barMidPoint) / bar_speed; %ms

sp = 1E3 * double(sp) / sample_rate - pre_time; %convert to ms to match pre, stim, tailTime and make stim onset = 0

spikes_leading = length(find(sp>0 & sp<=timeToMidPoint));
spikes_trailing = length(find(sp>timeToMidPoint & sp<=stim_time));