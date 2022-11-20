function required_fields = plot_EpochRawData(R,ax)
if nargin < 1
    required_fields = {'file_name','epoch_number'};
    return;
end

ep_struct = fetch(sln_symphony.ExperimentEpochChannel * ...
    sln_symphony.ExperimentChannel * ...
    sln_symphony.ExperimentElectrode ...
    & R, '*');
data = ep_struct.raw_data;
L = length(data);
timeAxis = (1:L) / ep_struct.sample_rate;
plot(ax, timeAxis, data, 'k');
xlabel(ax,'Time (s)');
set(ax,'XtickMode','auto');
% %look for spike data
spike_train = sln_symphony.SpikeTrain & R;
if spike_train.count == 1
    sp = fetch1(spike_train,'spike_indices');
    hold(ax,'on');
    scatter(ax, timeAxis(sp), data(sp), 'rx');
    hold(ax,'off');
end
if strcmp(ep_struct.amp_mode,'Cell attached')
    set(ax,'Ytick',[]);
    ylabel(ax,'');
else
    set(ax,'YtickMode','auto');
    if strcmp(ep_struct.recording_mode,'Current clamp')
         ylabel(ax,'mV');
    else
        ylabel(ax,'pA');
    end
end


