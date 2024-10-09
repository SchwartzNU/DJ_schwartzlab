function [indices, waveforms, user_data] = detectEvents(data, sample_rate, thresh, refractory, window, waveform_sample_rate, user_data)

[~,indices] = findpeaks(sign(thresh) * data,  'minpeakheight', abs(thresh), 'minpeakdistance', refractory * sample_rate);

if isempty(indices)
    waveforms = [];
    return
end

ii = indices + ((-window+1):window)'; %indices of data in windows around events
ii(ii<1) = 1;
ii(ii>length(data)) = length(data);

% waveforms = reshape(resample(data(ii), waveform_sample_rate, sample_rate), [], length(indices)); %upsample waveforms
waveforms = data(ii')';
end