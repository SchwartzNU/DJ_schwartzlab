function alignFunctionalImagingDataForDataset(ds, Nchannels, useChannel)
%this assumes that the .json files extracting the epoch times are already
%in the folder
%ds is a dataset with the cellName in there from sln_cell.cellName
constant_offset_ms = 300;

cellName = fetch1(ds,'cell_name');
dataset_name = fetch1(ds,'dataset_name');

epochs = sln_symphony.DatasetEpoch * sln_symphony.ExperimentEpoch & ds;
epoch_starts = fetchn(epochs,'epoch_start_time');
epoch_durations_ms = fetchn(epochs,'epoch_duration');
epoch_ids = fetchn(epochs,'epoch_id');
exp_start = fetch1(sln_symphony.Experiment & ds, 'experiment_start_time');
epoch_times = datetime(exp_start) + milliseconds(epoch_starts) - milliseconds(constant_offset_ms);

imaging_dir = [getenv('Func_imaging_folder') filesep cellName filesep '*.json'];
D = dir(imaging_dir);
JSON_file_path = [];
for i=1:length(D)
    name = extractBefore(D(i).name,'.json');
    if endsWith(name, dataset_name)
        JSON_file_path = [extractBefore(imaging_dir,'*.json') filesep name '.json'];
        break;
    end
end

if ~isempty(JSON_file_path)
    jf = fileread([JSON_file_path]);
    time_stamps_struct = jsondecode(jf);
else
    disp('json not found.');
    return
end

im_file = sprintf('%s_ch%d.tif', name, useChannel);
image_fname = [extractBefore(imaging_dir,'*.json') 'deinterleaved_and_drift_corrected' filesep im_file];
info = imfinfo(image_fname);
w = info(1).Width;
h = info(1).Height;
N_frames = length(info);
V = uint16(zeros(h, w, N_frames));

for i=1:N_frames
    V(:,:,i) = imread(image_fname,i);
end

frame_starts = time_stamps_struct.time_array(1:Nchannels:end);
frame_times = datetime(time_stamps_struct.matlab_time_string) + seconds(frame_starts);

frame_period = frame_times(2) - frame_times(1);
frame_period_s = seconds(frame_period);
frame_rate = 1./frame_period_s;

N_epochs = length(epoch_times);
start_frame = zeros(N_epochs,1);
end_frame = zeros(N_epochs,1);
shift_ms = zeros(N_epochs, 1);

epoch_aligned_dir = [extractBefore(image_fname, '.tif'), '_epochAligned'];
if ~isfolder(epoch_aligned_dir)
    mkdir(epoch_aligned_dir);
end

for i=1:N_epochs
    [~, ind] = min(abs(epoch_times(i) - frame_times));
    start_frame(i) = ind;
    end_frame(i) = ind + ceil((epoch_durations_ms(i)/1E3)/frame_period_s);
    shift = epoch_times(i) - frame_times(ind);
    shift_ms(i) = seconds(shift)*1E3;    

    t = Tiff(sprintf('%s%sepoch_%d.tif', epoch_aligned_dir, filesep, epoch_ids(i)), 'w');

    setTag(t,'Photometric',Tiff.Photometric.MinIsBlack);
    setTag(t,'Compression',Tiff.Compression.None);
    setTag(t,'BitsPerSample',info(1).BitDepth);
    setTag(t,'SamplesPerPixel',end_frame(i) - start_frame(i) + 1);
    setTag(t,'SampleFormat',Tiff.SampleFormat.UInt);
    setTag(t,'ExtraSamples',Tiff.ExtraSamples.Unspecified);
    setTag(t,'ImageLength',h);
    setTag(t,'ImageWidth',w);
    planarConfig = info(1).PlanarConfiguration;
    setTag(t,'PlanarConfiguration',Tiff.PlanarConfiguration.(planarConfig));
    write(t, V(:,:,start_frame(i):end_frame(i)));
    close(t);
end

dlmwrite([epoch_aligned_dir, filesep, 'ms_shifts.txt'], [epoch_ids, shift_ms]);

% Read timestamps from JSON
%

