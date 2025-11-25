function required_fields = plot_psc_raster(R, ax)

if nargin < 1
    required_fields = {'psc_amp_mean'};
    %most data in this plotter is pulling from epoch analysis of psc detection but since it is an Dataset level plotter,
    %require this to prevent it showing up in unrelated dataset
    return;
end

%modify bin size if you need
binsize = 2; %unit (ms)

%query data
q.file_name = R.file_name;
q.dataset_name = R.dataset_name;
q.source_id = R.source_id;

if(R.if_multi_pulse)
    data =fetch(sln_symphony.DatasetEpoch * sln_results.EpochPostsynapticCurrent...
        *aka.EpochParams('OptopulseTrain') * aka.BlockParams('OptopulseTrain')&q, ...
        'psc_amplitude', 'psc_start_ms', 'psc_total', 'pre_time', 'stim_time', 'tail_time', 'sample_rate');
else
    data =fetch(sln_symphony.DatasetEpoch * sln_results.EpochPostsynapticCurrent...
        *aka.EpochParams('OptoPulse') * aka.BlockParams('OptoPulse') & q, ...
        'psc_amplitude', 'psc_start_ms', 'psc_total', 'pre_time', 'stim_time', 'tail_time', 'sample_rate');
end

%making raster data
N_epoch = numel(data);
total_time_ms = data(1).pre_time + data(1).stim_time + data(1).tail_time;
if (mod(total_time_ms, binsize))
    fprintf('WARNING: epoch lasped time cannot be divided evenly by binsize. Considering change the binsize!\n');
    raster_data = zeros([N_epoch, idivide(total_time_ms, int16(binsize))+1]);
else
    raster_data = zeros([N_epoch, total_time_ms/binsize]);
end

%going through each epoch in data to find psc
for i = 1:N_epoch
    if(data(i).psc_total)
        timing = data(i).psc_start_ms;
        raster_bins = zeros([data(i).psc_total, 1]);
        for j = 1:numel(raster_bins)
            if (mod(timing(j), int16(binsize)))
                raster_bins(j) = 1+idivide(timing(j), int16(binsize));
            else
                raster_bins(j) = idivide(timing(j), int16(binsize));
            end
        end
        raster_data(i, raster_bins) =1;
    end
end

%now plot
imagesc(ax, raster_data);
colormap(ax, sky);
%colorbar(ax);
ylabel(ax, 'Epoch number');
label_stc = sprintf('Bin number, size: %d ms', binsize);
xlabel(ax, label_stc);
ylim(ax, [1, N_epoch]);
xlim(ax, [0,  idivide(total_time_ms, int16(binsize))+1]);
set(ax,'XtickMode', 'auto');
set(ax, 'YtickMode', 'auto');

%adding opto start and end lines
hold(ax, "on");
xline(ax, data(1).pre_time/binsize, '-', 'Color', 'black');
xline(ax, (data(1).pre_time+data(1).stim_time)/binsize, '--', 'Color', 'black');
hold(ax, "off");
end

