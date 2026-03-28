%% project script for HFD animals
% We are going to look at 3 kinds of datasets
%1. SpotsMultiSize Cell-attached, CA_SMS, to measure light responses
%2. MultiPulse, Current-clamp, CC_MP, to measure intrinsic electrical properties
%3. SpotsMultiSize, Voltage-clamp, VC_SMS, to measure synaptic inputs 

%And some control data
%4. SMS WT CA data (at least for a few cell types)
%5. MP control data CC

%We will compare cells (within type) from high fat diet (HFD) animals and
%sibling controls. We can also query larger sets of control data down the
%line.

%%I made a query for each of these dataset types in DataGrouper. I will
%%post screenshots. 

%% load saved queries

%SMS controls
q_CA_ON_alpha = sln_lab.Query & 'query_name="SMS_CA_ON_alpha_clean"';
q_CA_OFF_tr_alpha = sln_lab.Query & 'query_name="SMS_CA_OFF_trans_alpha_clean"';
q_CA_OFF_sus_alpha = sln_lab.Query & 'query_name="SMS_CA_OFF_sus_alpha_clean"';
q_CA_ON_tr_MeRF = sln_lab.Query & 'query_name="SMS_CA_ON_tr_MeRF_clean"';

%SMS HFD
q_CA_SMS_HFD = sln_lab.Query & 'query_name="SMS_CA_HFD_all_clean"';

%CC controls
q_CC_MP_control = sln_lab.Query & 'query_name="MP_CC_control_RGCs"';

%CC HFD
q_CC_MP_HFD = sln_lab.Query & 'query_name="MP_HFD_all_clean"';

%VC SMS 
q_VC_SMS_HFD_exc = sln_lab.Query & 'query_name="SMS_VC_HFD_exc"';
q_VC_SMS_HFD_inh = sln_lab.Query & 'query_name="SMS_VC_HFD_inh"';

q_VC_SMS_control_exc = sln_lab.Query & 'query_name="SMS_VC_control_clean_exc"';
q_VC_SMS_control_inh = sln_lab.Query & 'query_name="SMS_VC_control_clean_inh"';

%% fetch all the data from each one (the slow step)
%Once this is done once, you can just save them and load them directly from
%the .mat files

%% SMS CA
tic;
ON_alpha_temp = q_CA_ON_alpha.runAndFetchAnalysisResult('DatasetSMSCA');
OFF_tr_alpha_temp = q_CA_OFF_tr_alpha.runAndFetchAnalysisResult('DatasetSMSCA');
OFF_sus_alpha_temp = q_CA_OFF_sus_alpha.runAndFetchAnalysisResult('DatasetSMSCA');
ON_tr_MeRF_temp = q_CA_ON_tr_MeRF.runAndFetchAnalysisResult('DatasetSMSCA');
fprintf('CA SMS data fetch took %f seconds\n', toc);

SMS_CA_controls = [ON_alpha_temp; ...
    OFF_tr_alpha_temp; ...
    OFF_sus_alpha_temp; ...
    ON_tr_MeRF_temp  ...
    ];

%strip fields
SMS_CA_controls = rmfield(SMS_CA_controls, ...
    { ...
    'notes', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

SMS_CA_HFD = q_CA_SMS_HFD.runAndFetchAnalysisResult('DatasetSMSCA');

%strip fields
SMS_CA_HFD = rmfield(SMS_CA_HFD, ...
    { ...
    'notes', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

%add feeding_condition
SMS_CA_controls_copy = SMS_CA_controls;
for i=1:length(SMS_CA_controls)
    q = sln_symphony.UserParamAnimalFeedingCondition & SMS_CA_controls(i);
    if exists(q)
        SMS_CA_controls_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        SMS_CA_controls_copy(i).feeding_condition = '';
    end
end
SMS_CA_controls = SMS_CA_controls_copy;
clear SMS_CA_controls_copy;

SMS_CA_HFD_copy = SMS_CA_HFD;
for i=1:length(SMS_CA_HFD)
    q = sln_symphony.UserParamAnimalFeedingCondition & SMS_CA_HFD(i);
    if exists(q)
        SMS_CA_HFD_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        SMS_CA_HFD_copy(i).feeding_condition = '';
    end
end
SMS_CA_HFD = SMS_CA_HFD_copy;
clear SMS_CA_HFD_copy;

T_controls = struct2table(SMS_CA_controls);
T_HFD = struct2table(SMS_CA_HFD);

T_SMS_CA_FULL = [T_controls; T_HFD];

%% SMS VC
tic;
SMS_VC_control_exc = q_VC_SMS_control_exc.runAndFetchAnalysisResult('DatasetSMSVC');
SMS_VC_control_inh = q_VC_SMS_control_inh.runAndFetchAnalysisResult('DatasetSMSVC');

SMS_VC_HFD_exc = q_VC_SMS_HFD_exc.runAndFetchAnalysisResult('DatasetSMSVC');
SMS_VC_HFD_inh = q_VC_SMS_HFD_inh.runAndFetchAnalysisResult('DatasetSMSVC');
fprintf('VC SMS data fetch took %f seconds\n', toc);

SMS_VC_control_exc = rmfield(SMS_VC_control_exc, ...
    { ...
    'notes', ...
    'user_name', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

SMS_VC_control_inh = rmfield(SMS_VC_control_inh, ...
    { ...
    'notes', ...
    'user_name', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

SMS_VC_HFD_exc = rmfield(SMS_VC_HFD_exc, ...
    { ...
    'notes', ...
    'user_name', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

SMS_VC_HFD_inh = rmfield(SMS_VC_HFD_inh, ...
    { ...
    'notes', ...
    'user_name', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

%add feeding_condition
SMS_VC_control_exc_copy = SMS_VC_control_exc;
for i=1:length(SMS_VC_control_exc)
    q = sln_symphony.UserParamAnimalFeedingCondition & SMS_VC_control_exc(i);
    if exists(q)
        SMS_VC_control_exc_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        SMS_VC_control_exc_copy(i).feeding_condition = '';
    end
end
SMS_VC_control_exc = SMS_VC_control_exc_copy;
clear SMS_VC_control_exc_copy;

%add feeding_condition
SMS_VC_control_inh_copy = SMS_VC_control_inh;
for i=1:length(SMS_VC_control_inh)
    q = sln_symphony.UserParamAnimalFeedingCondition & SMS_VC_control_inh(i);
    if exists(q)
        SMS_VC_control_inh_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        SMS_VC_control_inh_copy(i).feeding_condition = '';
    end
end
SMS_VC_control_inh = SMS_VC_control_inh_copy;
clear SMS_VC_control_inh_copy;

%add feeding_condition
SMS_VC_HFD_exc_copy = SMS_VC_HFD_exc;
for i=1:length(SMS_VC_HFD_exc)
    q = sln_symphony.UserParamAnimalFeedingCondition & SMS_VC_HFD_exc(i);
    if exists(q)
        SMS_VC_HFD_exc_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        SMS_VC_HFD_exc_copy(i).feeding_condition = '';
    end
end
SMS_VC_HFD_exc = SMS_VC_HFD_exc_copy;
clear SMS_VC_HFD_exc_copy;

%add feeding_condition
SMS_VC_HFD_inh_copy = SMS_VC_HFD_inh;
for i=1:length(SMS_VC_HFD_inh)
    q = sln_symphony.UserParamAnimalFeedingCondition & SMS_VC_HFD_inh(i);
    if exists(q)
        SMS_VC_HFD_inh_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        SMS_VC_HFD_inh_copy(i).feeding_condition = '';
    end
end
SMS_VC_HFD_inh = SMS_VC_HFD_inh_copy;
clear SMS_VC_HFD_inh_copy;

SMS_VC_full = [SMS_VC_control_exc; SMS_VC_control_inh; SMS_VC_HFD_exc; SMS_VC_HFD_inh];
data = SMS_VC_full;
data = rmfield(data,'mean_traces');
save('SMS_CV_full', 'data');

%% MP CC
tic;
data_CC_MP_control_features = q_CC_MP_control.runAndFetchAnalysisResult('DatasetMultiPulsevaryCurrentFeatureExtract');
fprintf('CC MP control data fetch took %f seconds\n', toc);

tic;
data_CC_MP_control_FI = q_CC_MP_control.runAndFetchAnalysisResult('DatasetMultiPulseFIcurve');
fprintf('CC MP control data fetch took %f seconds\n', toc);

tic;
data_CC_MP_HFD_features = q_CC_MP_HFD.runAndFetchAnalysisResult('DatasetMultiPulsevaryCurrentFeatureExtract');
fprintf('CC MP HFD data fetch took %f seconds\n', toc);

tic;
data_CC_MP_HFD_FI = q_CC_MP_HFD.runAndFetchAnalysisResult('DatasetMultiPulseFIcurve');
fprintf('CC MP HFD data fetch took %f seconds\n', toc);

data_CC_MP_control_FI = rmfield(data_CC_MP_control_FI, ...
    { ...
    'notes', ...
    'user_name', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

data_CC_MP_HFD_FI = rmfield(data_CC_MP_HFD_FI, ...
    { ...
    'notes', ...
    'user_name', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

%add feeding_condition
data_CC_MP_control_FI_copy = data_CC_MP_control_FI;
for i=1:length(data_CC_MP_control_FI)
    q = sln_symphony.UserParamAnimalFeedingCondition & data_CC_MP_control_FI(i);
    if exists(q)
        data_CC_MP_control_FI_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        data_CC_MP_control_FI_copy(i).feeding_condition = '';
    end
end
data_CC_MP_control_FI = data_CC_MP_control_FI_copy;
clear data_CC_MP_control_FI_copy;

%add feeding_condition
data_CC_MP_HFD_FI_copy = data_CC_MP_HFD_FI;
for i=1:length(data_CC_MP_HFD_FI)
    q = sln_symphony.UserParamAnimalFeedingCondition & data_CC_MP_HFD_FI(i);
    if exists(q)
        data_CC_MP_HFD_FI_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        data_CC_MP_HFD_FI_copy(i).feeding_condition = '';
    end
end
data_CC_MP_HFD_FI = data_CC_MP_HFD_FI_copy;
clear data_CC_MP_HFD_FI_copy;

data = [data_CC_MP_control_FI; data_CC_MP_HFD_FI];
save('MP_CC_FI_full','data');

data_CC_MP_control_features = rmfield(data_CC_MP_control_features, ...
    { ...
    'notes', ...
    'user_name', ...
    'example_traces', ...
    'mean_traces', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

data_CC_MP_HFD_features = rmfield(data_CC_MP_HFD_features, ...
    { ...
    'notes', ...
    'user_name', ...
    'example_traces', ...
    'mean_traces', ...
    'git_tag', ...
    'entry_time', ...
    'event_id' ...
    });

%add feeding_condition
data_CC_MP_control_features_copy = data_CC_MP_control_features;
for i=1:length(data_CC_MP_control_features)
    q = sln_symphony.UserParamAnimalFeedingCondition & data_CC_MP_control_features(i);
    if exists(q)
        data_CC_MP_control_features_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        data_CC_MP_control_features_copy(i).feeding_condition = '';
    end
end
data_CC_MP_control_features = data_CC_MP_control_features_copy;
clear data_CC_MP_control_features_copy;

%add feeding_condition
data_CC_MP_HFD_features_copy = data_CC_MP_HFD_features;
for i=1:length(data_CC_MP_HFD_features)
    q = sln_symphony.UserParamAnimalFeedingCondition & data_CC_MP_HFD_features(i);
    if exists(q)
        data_CC_MP_HFD_features_copy(i).feeding_condition = fetch1(q,'feeding_condition');
    else
        data_CC_MP_HFD_features_copy(i).feeding_condition = '';
    end
end
data_CC_MP_HFD_features = data_CC_MP_HFD_features_copy;
clear data_CC_MP_HFD_features_copy;

data = [data_CC_MP_control_features; data_CC_MP_HFD_features];
save('MP_CC_features_full','data');

%% Each of these is a struct with entries corresponding to datasets. 
%For example:
% data_CA_SMS = 
% 
%   struct with fields:
% 
%             animal_id: [85×1 double]
%             file_name: {85×1 cell}
%             source_id: [85×1 double]
%             cell_unid: [85×1 double]
%                  side: {85×1 cell}
%          dataset_name: {85×1 cell}
%             user_name: {85×1 cell}
%      baseline_rate_hz: [85×1 double]
%            entry_time: {85×1 cell}
%               git_tag: {85×1 cell}
%     n_epochs_per_size: {85×1 cell}
%           pre_time_ms: [85×1 double]
%                psth_x: {85×1 cell}
%              sms_psth: {85×1 cell}
%       spikes_pre_mean: {85×1 cell}
%      spikes_stim_mean: {85×1 cell}
%       spikes_stim_sem: {85×1 cell}
%      spikes_tail_mean: {85×1 cell}
%       spikes_tail_sem: {85×1 cell}
%            spot_sizes: {85×1 cell}
%          stim_time_ms: [85×1 double]
%          tail_time_ms: [85×1 double]
%      source_id_retina: [85×1 double]
%          experimenter: {85×1 cell}
%           orientation: {85×1 cell}
%             retina_id: [85×1 double]
%           cell_number: [85×1 double]
%           online_type: {85×1 cell}
%                     x: [85×1 double]
%                     y: [85×1 double]
%              event_id: [85×1 double]
%             cell_type: {85×1 cell}
%            cell_class: {85×1 cell}
%                 notes: {85×1 cell}
%             cell_name: {85×1 cell}
%       retina_quadrant: {85×1 cell}
%                   dob: {85×1 cell}
%                   sex: {85×1 cell}
%           strain_name: {85×1 cell}
%       background_name: {85×1 cell}
%         animal_source: [85×1 double]

%This has 85 datasets in it. Each variable is aligned by the dataset.
%Remember, 85 datasets is not necessarily 85 cells, because there might be
%duplicates. 
%Many of the variables should be reasonably self-explanatory by name.
%Information about others can be found in the excel file corresponding to
%each analysis. 
%For this example:
%DJ_SchwartzLab/result_table_templates/SMSCA.xlsx

%Pasted here:
% Field	            Type	Description
% file_name	        string	file name from symphony
% dataset_name	    string	dataset name
% source_id	        uint16	source id used to identify the cell to which the dataset belongs
% baseline_rate_hz	double	baseline firing rate (in pre time) averaged across spot sizes (Hz)
% n_epochs_per_size	cell	vector with how many trials for each spot size
% pre_time_ms	    double	time before stimulus onset (ms)
% psth_x	        cell	x (time) values for psth (seconds)
% sms_psth	        cell	full SMS psth image with 10 ms bins or other binning if specified in params
% spikes_pre_mean	cell	spike count in pre time, mean
% spikes_stim_mean	cell	spike count in stim time, mean
% spikes_stim_sem	cell	spike count in stim time, standard error of the mean
% spikes_tail_mean	cell	spike count in tail time, mean
% spikes_tail_sem	cell	spike count in tail time, standard error of the mean
% spot_sizes	    cell	set of spot sizes (microns)
% stim_time_ms	    double	stimulus presentation time (ms)
% tail_time_ms	    double	time after stimulus offset (ms)
