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
%1
q_CA_SMS = sln_lab.Query & 'query_name="HFD_and_siblings_CA_SMS"';

%2
q_CC_MP = sln_lab.Query & 'query_name="HFD_and_siblings_CC_MP"';

%3
q_VC_SMS = sln_lab.Query & 'query_name="HFD_and_siblings_VC_SMS"';
   
%5 
q_MP_control = sln_lab.Query & 'query_name="MP_control_CC_WIP"';


%% fetch all the data from each one (the slow step)
%Once this is done once, you can just save them and load them directly from
%the .mat files
tic;
data_CA_SMS = q_CA_SMS.runAndFetchAnalysisResult('DatasetSMSCA');
fprintf('CA SMS data fetch took %f seconds\n', toc);

tic;
data_CC_MP_features = q_CC_MP.runAndFetchAnalysisResult('DatasetMultiPulsevaryCurrentFeatureExtract');
fprintf('CC MP data fetch took %f seconds\n', toc);

tic;
data_CC_MP_FI = q_CC_MP.runAndFetchAnalysisResult('DatasetMultiPulseFIcurve');
fprintf('CC MP data fetch took %f seconds\n', toc);

tic;
data_MP_control_features = q_MP_control.runAndFetchAnalysisResult('DatasetMultiPulsevaryCurrentFeatureExtract');
fprintf('CC MP control data fetch took %f seconds\n', toc);

tic;
data_MP_control_FI = q_MP_control.runAndFetchAnalysisResult('DatasetMultiPulseFIcurve');
fprintf('CC MP control data fetch took %f seconds\n', toc);


tic;
data_VC_SMS = q_VC_SMS.runAndFetchAnalysisResult('DatasetSMSVC');
fprintf('VC SMS data fetch took %f seconds\n', toc);


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
