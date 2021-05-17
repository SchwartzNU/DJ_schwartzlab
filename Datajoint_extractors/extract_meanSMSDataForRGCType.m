function  = extract_meanSMSData(cell_type_name, fname)
queryResult = sl.SymphonyRecordedCell * sl_greg.DatasetResult * sl_mutable.CurrentCellType & ...
sprintf('cell_type="%s"',cell_type_name) & 'pipeline_name="typology_SMS_CA"';
SMS_struct = fetch(queryResult, 'spotSize', 'sms_psth', 'psth_x');

size_min = 1;
size_max = 1200;
size_bins = 50;

N_cells = length(SMS_struct);

data = {SMS_struct.sms_psth}'; %a cell array of PSTHs
timeVec = {SMS_struct.psth_x}';
sizeVec = {SMS_struct.spotSize}'; %a cell array of spot sizes matching the PSTHs
sizeBins = logspace(size_min,log10(size_max), size_bins); %an example list of desired spot sizes;
timeRange = [-1 2];

dt = .01; %time bin (s)
%sizeBins and timeRange are not quite in right format
[sizeInd,tind] = meshgrid(sizeBins,timeRange(1):dt:timeRange(2));
%timeVec must be in the form of a list of start and end times
tMin = cellfun(@min,timeVec);
tMax = cellfun(@max,timeVec);
timeVec = [tMin tMax];
%need to make sure index vectors are in correct orientation, see help rebinData for guidance
data_rebinned = rebinData(data,sizeVec,(sizeInd(:))',timeVec,tind(:),dt);
data_rebinned = reshape(data_rebinned,[numel(data) size(sizeInd)]);
sms_psth_mean = squeeze(mean(data_rebinned,1))';



