RGC_types = fetchn(sl.CellType & 'cell_class = "RGC"','name_full');
data_by_rgc_type = {};

for i=1:length(RGC_tyes)
    i
    RGC_tyes{i}
    tic;
    q = sl.Epoch * sl_mutable.CurrentCellType ...
        & sprintf('cell_type = "%s"', RGC_types{i}) ...
        & 'recording_mode = "Cell attached"' ...
        & 'protocol_name LIKE "Spots%"';
    
    epochData = fetch(q);

    N = q.count;
    allParams = fetchn(q, 'protocol_params');
    spotSizes = zeros(N,1);

    for n=1:N
        spotSizes(n) = allParams{n}.curSpotSize;
        epochData(n).spotSize = spotSizes;
        [epochData(n).timeAxis, epochData(n).data] = epochRawData(epochData(n).cell_id, epochData(n).epoch_number, 1);
        
    end
    toc;
    data_by_rgc_type{i} = epochData;
end


