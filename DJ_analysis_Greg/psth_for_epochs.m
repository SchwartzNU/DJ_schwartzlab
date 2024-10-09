function [psth_x, psth_y] = psth_for_epochs(epochs, binSize, time_shift, baseline_subtract, gauss_win, sliding_win)
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
    time_shift = 0;
end
if nargin < 2
    binSize = 10;
end

sample_rate = unique(fetchn(sln_symphony.ExperimentChannel & epochs, 'sample_rate')); %Hz
if length(sample_rate) > 1
    error('Epochs in PSTH calculation do not have the same sample rate');
end

duration = unique(fetchn(epochs,'epoch_duration')); %total duration of epoch in ms
if length(duration) > 1
    error('Epochs in PSTH calculation do not have the same duration');
end

N_epochs = epochs.count;

spikes_query = aka.SpikeTrain & epochs;
sp = fetchn(spikes_query,'spike_indices');
sp = [sp{:}]; %concatenate all spikes together

bins = 0:binSize:duration;

if isempty(sp)
    spCount = zeros(1,length(bins));
else
    sp = double(sp) * 1000 / sample_rate; %samples to ms
    spCount = histcounts(sp,bins);
end

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
psth_y = 1E3 * spCount ./ (N_epochs * binSize);
psth_x = bins(1:end-1) / 1E3; % units of seconds
psth_y = psth_y(1:length(psth_x));
