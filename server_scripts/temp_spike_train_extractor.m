sl_epochs = sl_mutable.SpikeTrain * sl.SymphonyRecordedCell * sl_mutable.CurrentCellType * sl.Epoch & 'recording_mode = "Cell attached"';
spike_trains_meta_data = fetch(sl_epochs,'*');

N_trains = length(spike_trains_meta_data)
trains_per_file = 5000

storage_location = '/mnt/fsmresfiles/AnimalLogs/exportedData/';

z=1;
p = 1;
while z < N_trains
    tic;
    sp_trains = repmat(struct,trains_per_file,1);
    for i=1:trains_per_file
        i
        sp_trains(i).dataset_index = z;
        sp_trains(i).cell_unid = spike_trains_meta_data(z).cell_unid;
        sp_trains(i).cell_type = spike_trains_meta_data(z).cell_type;
        sp_trains(i).sample_rate = spike_trains_meta_data(z).sample_rate;
        sp_trains(i).sp = spike_trains_meta_data(z).sp;
        [~, sp_trains(i).data] = epochRawData(spike_trains_meta_data(z).cell_id, spike_trains_meta_data(z).epoch_number, spike_trains_meta_data(z).channel);
        z=z+1;
        if z > N_trains
            break;
        end
    end
    fname = sprintf('%sspike_trains_part_%02d', storage_location, p)
    fprintf('Time elapsed: %d\n', toc);
    save(fname, 'sp_trains','-v7.3')
    %z=z+trains_per_file;
    p=p+1;
end