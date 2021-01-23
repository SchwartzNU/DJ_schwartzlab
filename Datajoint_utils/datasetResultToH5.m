function [] = datasetResultToH5(cell_id, dataset_name, user_db, fname_prefix)
if nargin<4
    fname_prefix = '';
end

if ~isempty(fname_prefix)
    fileName = [fname_prefix '_' cell_id '.h5'];
else
    fileName = [cell_id '.h5'];
end

if ~exist(fileName, 'file')
    fid = fopen(fileName, 'w');
    fclose(fid);
end

ds_result = eval(sprintf('%s.DatasetResult', user_db)) & sprintf('cell_id="%s"', cell_id) & sprintf('dataset_name="%s"', dataset_name);
if ~ds_result.exists %try dataset name as prefix
    ds_result = eval(sprintf('%s.DatasetResult', user_db)) & sprintf('cell_id="%s"', cell_id) & sprintf('dataset_name LIKE "%s%%"', dataset_name);
end

if ~ds_result.exists
    disp('Failed to find result');
elseif ds_result.count > 1
    resp = input('Found multiple matching datasets: save all [y|n]', 's');
    if strcmp(resp, 'y')
        Rset = ds_result.fetchn('result');
        ds_name = ds_result.fetchn('dataset_name');
        for r=1:ds_result.count
            R = Rset{r};
            fields = fieldnames(R);
            for i = 1:length(fields)
                if ~isempty(R.(fields{i}))
                    hdf5write(fileName, sprintf('/%s/%s', ds_name{r}, fields{i}), R.(fields{i}), 'WriteMode', 'append');
                end
            end
        end
    end
else
    R = ds_result.fetch1('result');
    ds_name = ds_result.fetch1('dataset_name');
    fields = fieldnames(R);
    for i = 1:length(fields)
        if ~isempty(R.(fields{i}))
            hdf5write(fileName, sprintf('/%s/%s', ds_name, fields{i}), R.(fields{i}), 'WriteMode', 'append');
        end
    end
end