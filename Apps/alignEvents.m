function [waveforms,i] = alignEvents(waveforms)
% circularly shifts the waveforms so that they have maximal
% cross-correlation with the mean signal

[T,~] = size(waveforms);


% calculate the time-reversed cross-correlation
% NOTE:
%  (1) fft(xcorr(a,b)) = fft(a) .* conj(fft(a)) 
%  (2) fft operates in periodic domain; zero-padding prevents overlap

wfmz = cat(1,mean(waveforms,2),zeros(T-1,1));
wf_z = padarray(waveforms,[T-1,0],'post');

xc_r = circshift(ifft(fft(wf_z) .* conj(fft(wfmz))),T-1);

[~,i] = max(xc_r,[],1); %for each event, the best offset

%Needs to be something like 2T-1-i?
waveforms = cell2mat(arrayfun(@(x) circshift(waveforms(:,x),-i(x)), 1:size(waveforms,2), 'uni', 0));
% waveforms = cell2mat(rowfun(@(w,i) circshift(w,i), waveforms',i', 'uni', 0));

% app.event_offsets = i - max_o + 1;
% app.event_counts = cellfun(@length,app.event_indices);
% eo = mat2cell(app.event_offsets, 1, app.event_counts)';
% app.event_indices = cellfun(@(x,y,z) x + round(y/100000*z), app.event_indices, eo, {app.epoch_data(:).sample_rate}', 'uni', 0);
% app.is_spike = false(sum(app.event_counts),1);
% app.event_waveforms = cell2mat(arrayfun(@(x) circshift(app.event_waveforms(:,x),app.event_offsets(x)), 1:size(app.event_waveforms,2), 'uni', 0));



end