function sp_count = spikes_in_interval(epoch,pre_stim_tail,interval_name,bounds)
%epoch: struct with the primary key of the epoch
%pre_stim_tail: struct with pre_time, stim_time, and tail_time (in ms)
%interval_name: 'pre', 'stim', or 'tail'
%bounds: array with bounds relative to selected interval. 0 is exactly at
%the interval, negative is before, and positive is after. For example, this
%command:
%sp_count = spikes_in_interval(epoch,pre_stim_tail,'stim',[-100, 200])
%will count spike from 100 ms before the start of the stimulus interval to
%200 ms after the end of the stimulus interval.

if nargin<4
    bounds = [0, 0];
end

sample_rate = fetch1(sln_symphony.ExperimentChannel & epoch, 'sample_rate'); %Hz
spikes_query = aka.SpikeTrain & epoch;
if spikes_query.exists
    spike_times = fetch1(spikes_query,'spike_indices'); %grab spike times
else %assume no spieks
    spike_times = [];
end

duration = fetch1(aka.Epoch & epoch,'epoch_duration'); %total duration of epoch in ms

spike_times = 1E3 * double(spike_times) / sample_rate; %convert from samples to ms
switch interval_name
    case 'pre'
        interval_bounds = [0, pre_stim_tail.pre_time];
    case 'stim'
        interval_bounds =  [1/sample_rate + pre_stim_tail.pre_time, pre_stim_tail.pre_time + pre_stim_tail.stim_time];
    case 'tail'
        interval_bounds =  [1/sample_rate + pre_stim_tail.pre_time + pre_stim_tail.stim_time, duration];
    otherwise
        sp_count = nan;
        error('interval_name must be pre, stim, or tail');
end

interval = interval_bounds + bounds; %adjust interval by the bounds
sp_count = sum(spike_times >= interval(1) & spike_times <= interval(2));
