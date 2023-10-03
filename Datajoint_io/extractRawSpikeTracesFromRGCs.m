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
    saveN = min(N,N_epochs);
    epochDataOut = epochData(1:saveN);
    allParams = fetchn(q, 'protocol_params');

    for n=1:saveN
        epochDataOut(n).spotSize = allParams{n}.curSpotSize;
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


