function classifier_data = getClassiferSMSDatasets(classifier_labels, binSize)
%classifer labels is the table that is read in from 'classifier_include_types.txt'
SMS_all = (sl_greg.DatasetResult & 'pipeline_name="typology_SMS_CA"') - ...
    proj((sl_mutable.DatasetExcludeList & 'pipeline_name="typology_SMS_CA"'));


SMS_all_struct = SMS_all.fetch;
%classifier_data = struct;
all_types = classifier_labels.Type;
all_labels = classifier_labels.Label;

z = 1;
L = length(SMS_all_struct);
for i=1:L
    curType = fetch1(sl_mutable.CurrentCellType & SMS_all_struct(i), 'cell_type');
    ind = find(strcmp(all_types,curType));
    if ~isempty(ind)
        R = fetch1(sl_greg.DatasetResult & 'pipeline_name="typology_SMS_CA"' & SMS_all_struct(i), 'result');
                
        curLabel = all_labels{ind};
        s = rmfield(SMS_all_struct(i), {'pipeline_name', 'dataset_func_name'});
        s.SpotSizeVec = R.spotSize;
        s.label = curLabel;
        s.PSTH_X = R.psth_x;
        s.SMS_PSTH = R.sms_psth;
        
        if z==1
            classifier_data = s;
        else
            classifier_data(z) = s;
        end
        z=z+1
    end
end