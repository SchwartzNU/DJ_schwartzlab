N_epochs = 300;
RGC_types = fetchn(sl.CellType & 'cell_class = "RGC"','name_full');
%data_by_rgc_type = {};
save_dir = '/mnt/fsmresfiles/AnimalLogs/exportedData/';

for i=1:length(RGC_types)
    i
    RGC_types{i}
    tic;
    q = sl.Epoch * sl_mutable.CurrentCellType ...
        & sprintf('cell_type = "%s"', RGC_types{i}) ...
        & 'recording_mode = "Cell attached"' ...
        & 'protocol_name LIKE "Spots%"';
    
    epochData = fetch(q);

    N = q.count
    allParams = fetchn(q, 'protocol_params');
    spotSizes = zeros(N,1);

    for n=1:min(N,N_epochs)
        spotSizes(n) = allParams{n}.curSpotSize;
        epochDataOut(n) = epochData(n);
        epochDataOut(n).spotSize = spotSizes;
        try
            [epochDataOut(n).timeAxis, epochDataOut(n).data] = epochRawData(epochData(n).cell_id, epochData(n).epoch_number, 1);
        catch
            disp('Skipping epoch');
        end
    end
    toc;
    save(sprintf('%sraw_spike_data_%s.mat', save_dir, RGC_types{i}), 'epochDataOut');
    %data_by_rgc_type{i} = epochData;
end


