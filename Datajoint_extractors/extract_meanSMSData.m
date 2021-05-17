function [] = extract_meanSMSData()
allTypes = unique(fetchn(sl_mutable.CurrentCellType & 'cell_class="RGC"', 'cell_type'));
allTypes = setdiff(allTypes,'unknown');

for i=1:length(allTypes)
    allTypes{i}
    queryResult = sl.SymphonyRecordedCell * sl_greg.DatasetResult * sl_mutable.CurrentCellType & ...
        sprintf('cell_type="%s"',allTypes{i}) & 'pipeline_name="typology_SMS_CA"';
    R = fetchn(queryResult, 'result');
      
    size_min = 1;
    size_max = 1200;
    size_bins = 50;
    
    N_cells = length(R);
    data = {};
    timeVec = {};
    sizeVec = {};
    
    z=1;
    for j=1:N_cells
        if isfield(R{j}, 'sms_psth')
            data{z} = R{j}.sms_psth;
            timeVec{z} = R{j}.psth_x;
            sizeVec{z} = R{j}.spotSize';
            z=z+1;
        end
    end
    
%     data = {R{:}.sms_psth}'; %a cell array of PSTHs
%     timeVec = {R{:}.psth_x}';
%     sizeVec = {R{:}.spotSize}'; %a cell array of spot sizes matching the PSTHs

    data = data';
    timeVec = timeVec';
    sizeVec = sizeVec';
    
    sizeBins = logspace(size_min,log10(size_max), size_bins); %an example list of desired spot sizes;
    timeRange = [-1 2];
    
    dt = .01; %time bin (s)
    %sizeBins and timeRange are not quite in right format
    [sizeInd,tind] = meshgrid(sizeBins,timeRange(1):dt:timeRange(2));
    %keyboard;
    %timeVec must be in the form of a list of start and end times
    tMin = cellfun(@min,timeVec);
    tMax = cellfun(@max,timeVec);
    timeVec = [tMin tMax];
    %keyboard;
    %need to make sure index vectors are in correct orientation, see help rebinData for guidance
    data_rebinned = rebinData(data,sizeVec,(sizeInd(:))',timeVec,tind(:),dt);
    data_rebinned = reshape(data_rebinned,[numel(data) size(sizeInd)]);
    sms_psth_mean = squeeze(mean(data_rebinned,1))'; 
    sms_psth_sem = squeeze(std(data_rebinned,[],1)./sqrt(N_cells))'; 
    
    s = struct;
    s.SMS_PSTH = sms_psth_mean';
    s.SMS_PSTH_sem = sms_psth_sem';
    s.N_cells = N_cells;
    s
    
    exportStructToHDF5(s, ['SMS_PSTH_' allTypes{i} '.h5'], '/');
end
