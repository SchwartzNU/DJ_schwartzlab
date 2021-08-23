q = (sl_mutable.CellTypeValidation) * ...% & "validation_type!='none'") * ...
    (sl.Dataset & 'dataset_protocol_name="Spots Multi Size" OR dataset_protocol_name="Spots Multiple Sizes"' & ...
    "dataset_rstar_mean=0" & "dataset_recording_type='Cell attached'" & 'dataset_name NOT LIKE "%LightStep_fromSMS%"');

[cell_data, epoch_ids, protocol_name] = q.fetchn('cell_data','epoch_ids','dataset_protocol_name');
epoch_filter = struct('cell_data',cell_data,'protocol_name',protocol_name);

[cd_params, en_params, params]= fetchn(sl.Epoch & epoch_filter,'cell_data','epoch_number','protocol_params'); %super slow
epoch_data = table(cd_params, en_params, cellfun(@(x) x.preTime, params), cellfun(@(x) x.stimTime, params), cellfun(@(x) x.curSpotSize, params), 'variablenames',{'cell_data','epoch_number','preTime','stimTime','spotSize'});

cell_data = cellfun(@(x,y) repmat({x},1,numel(y)), cell_data, epoch_ids,'uniformoutput',false);

cell_data = cat(2,cell_data{:});
epoch_ids = cat(2,epoch_ids{:});

restriction = table(cell_data', epoch_ids', 'variablenames',{'cell_data','epoch_number'});
all_spikes = struct2table(fetch(sl_mutable.SpikeTrain * sl_mutable.CurrentCellType * ...
    (sl_mutable.CellTypeValidation),...% & 'validation_type!="none"'),...
    '*'));
spikes = innerjoin(restriction,all_spikes,'keys',{'cell_data','epoch_number'});
epochs_spikes = innerjoin(spikes, epoch_data, 'keys', {'cell_data','epoch_number'}); 

clear q all_spikes spikes epoch_data restriction cell_data cell_unid cd_params en_params params epoch_ids protocol_name epoch_filter;
%TODO: restriction, spikes, and final should all have same number of rows!! else
%there is a db issue

[g,epochs_avg] = findgroups(epochs_spikes(:,{'cell_unid','spotSize'}));
epochs_avg.hist = splitapply(@(varargin) makePSTHfromTable([50,200],varargin{:}), epochs_spikes(:,{'sp','preTime','stimTime'}), g);
[g,sms] = findgroups(epochs_avg(:,{'cell_unid'}));
sms.PSTH = splitapply(@(varargin) makePSTHfromPSTH(unique(epochs_avg.spotSize)', varargin{:}), epochs_avg(:,{'spotSize','hist'}), g);
%TODO: important! should only consider the training data in the above
%unique() call

clear epochs_avg epochs_spikes g;
sms = innerjoin(sms,...
    struct2table(fetch(sl_mutable.CurrentCellType * (sl_mutable.CellTypeValidation),...% & 'validation_type!="none"'),...
    'cell_type','validation_type')),...
    'keys',{'cell_unid'});

% train = cell2table(load('../partition210223.mat','partition').partition.trainNames,'variablenames',{'cell_id'});
% test = cell2table(load('../partition210223.mat','partition').partition.testNames,'variablenames',{'cell_id'});
% labelled_sms = innerjoin(sms, train, 'keys', {'cell_id'});
% test_sms = innerjoin(sms, test, 'keys', {'cell_id'});
train = struct2table(fetch(sl_mutable.ClassifierTrainingExample & "version=1"));
training_sms = innerjoin(sms, train(:,'cell_unid'),'keys',{'cell_unid'});
[~,i] = setdiff(sms(:,'cell_unid'), training_sms(:,'cell_unid'));
testing_sms = sms(i,:);

% has_confocal = innerjoin(sms, struct2table(fetch(sl_mutable.CellTypeValidation & 'validation_type="confocal image"')),'keys',{'cell_unid','animal_id','cell_id'});
oo_smrf = innerjoin(sms, table({'UHD','HD1','HD2','LED','F-mini-ON','F-mini-OFF'}','VariableNames',{'cell_type'}));
training_oo_smrf = innerjoin(oo_smrf(:,'cell_unid'), training_sms,'keys',{'cell_unid'});
testing_oo_smrf = innerjoin(oo_smrf(:,'cell_unid'), testing_sms,'keys',{'cell_unid'});


%%
cd = cell2mat(cellfun(@(x) x(:)', training_oo_smrf.PSTH,'uniformoutput',false));
[~,s,l] = pca(zscore(log(cd+eps))); %log-normalize the data before pca

labs = training_oo_smrf.cell_type;
[~,~,ib] = unique(labs);
% labs(~strcmp('confocal image', training_oo_smrf.validation_type) & ~strcmp('2P image', training_oo_smrf.validation_type)) = deal({'none'});
% labs(~strcmp('confocal image', training_oo_smrf.validation_type)) = deal({'none'});
labs(strcmp('none',training_oo_smrf.validation_type)) = deal({'none'});
[ulab,~,ia] = unique(labs);
ia(ia == find(strcmp('none',ulab))) = -1; %semi-supervised mode
clr = [0,1,0; .7,.7,.7; 0,1,1; 0,0,1; 1,0,1; 1, 0, 0];


[red, umap, clusters, extras] = run_umap(cat(2,cd,ia),'label_column','end');
% [red, umap, clusters, extras] = run_umap(cat(2,s(:,1:200),ia),'label_column','end');

figure(1);clf;
gscatter(red(:,1),red(:,2),training_oo_smrf.cell_type, clr([1 3:end],:))
figure(2);clf;
gscatter(red(:,1),red(:,2),labs, clr)

% [red, umap, clusters, extras] = run_umap(cat(2,cd,ia),'label_column','end');
[red, umap, clusters, extras] = run_umap(cat(2,s(:,1:25),ia),'label_column','end','n_neighbors',30);

figure(3);clf;
gscatter(red(:,1),red(:,2),training_oo_smrf.cell_type, clr([1 3:end],:))
figure(4);clf;
gscatter(red(:,1),red(:,2),labs, clr)



