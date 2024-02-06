function traces = getImageTracesForEpochWithROIs(ep, ROIs, baseline_ms)
fname_prefix = '_region2_hyperpol-Pulse_CC_set3_ch1'; %TODO: get this automatically

cellName = fetch1(ep,'cell_name');
imaging_dir = [getenv('Func_imaging_folder') filesep cellName ...
    filesep 'deinterleaved_and_drift_corrected' ...
    filesep cellName fname_prefix '_epochAligned'];

ms_shifts = readmatrix([imaging_dir filesep 'ms_shifts.txt']);
epoch_id = fetch1(ep,'epoch_id');
ind = find(ms_shifts(:,1)==epoch_id,1);
ms_shift = round(ms_shifts(ind,2));

im_fname = sprintf('%s%sepoch_%d.tif', imaging_dir, filesep, epoch_id);

V = imread(im_fname);
[r, c, Nframes] = size(V);

V_reshaped = reshape(V, [r*c, Nframes]);

dur_ms = fetch1(ep,'epoch_duration');
traces = zeros(ROIs.NumObjects, dur_ms); %1 ms resampling

tx = linspace(1,dur_ms,Nframes);
for i=1:ROIs.NumObjects
   curTrace = mean(V_reshaped(ROIs.PixelIdxList{i},:),1);
   curTrace = resample(curTrace, tx, 1, dur_ms, dur_ms, 'spline');
   curTrace = circshift(curTrace, ms_shift);
   baseline = mean(curTrace(1:baseline_ms));
   curTrace = (curTrace - baseline) / baseline; %dF/F
   traces(i,:) = curTrace;
end
