function [event_struct, stims, event_id_from_fname] = reconstruct_behavior_event_from_folder(basedir, fname, event_id_map)
if nargin < 3
    event_id_map = [];
end
fname
event_struct = struct;
stims = repmat(struct, 3, 1);

default_user = 'Devon';
default_camera_serial_number = 17391290;

event_struct.user_name = default_user;

folder_parts = strsplit(fname,filesep);
event_struct.animal_id = str2double(folder_parts{1});
sub_folder = folder_parts{2};
[event_id_from_fname, fname_remainder] = strtok(sub_folder,'_');

event_id_from_fname = str2double(event_id_from_fname);
%keyboard;
q = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession ...
    & sprintf('event_id=%d',event_id_from_fname) & sprintf('animal_id=%d',event_struct.animal_id);

if q.exists
   fprintf('SocialBehaviorSession event %d already in database.\n', event_id_from_fname);
   event_struct = struct;
   stims = repmat(struct, 3, 1);
   return;
elseif ~isempty(event_id_map)
    ind = find(event_id_map(:,1) == event_id_from_fname);
    if ind
         new_event_id = event_id_map(ind,2)
         q = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession ...
             & sprintf('event_id=%d',new_event_id) & sprintf('animal_id=%d',event_struct.animal_id);
         if q.exists
            fprintf('SocialBehaviorSession event %d in database matched to old id %d.\n', new_event_id, event_id_from_fname);
         else
            fprintf('Error in matching event %d\n', event_id_from_fname);
         end
    end
end

[event_struct.date, fname_remainder] = strtok(fname_remainder,'_');
fname_remainder = fname_remainder(2:end); %remove leading _

animal_types = fetchn(sl_behavior.TestAnimalType,'animal_type_name');
ind = cellfun(@(pat)startsWith(fname_remainder,pat), animal_types);
if sum(ind) ~= 1
    fprintf('Error finding animal type for string %s\n', fname_remainder);
    return;
end
event_struct.animal_type_name = animal_types{ind};
fname_remainder = extractAfter(fname_remainder,sprintf('%s_',animal_types{ind}));

[purpose_part, fname_remainder] = strtok(fname_remainder,'(');
if ~strcmp(purpose_part, 'habituation')
    purpose_part = purpose_part(1:end-1); %remove trailing _
end

purpose_names = fetchn(sl_behavior.SocialBehaviorExperimentType,'purpose');
ind = cellfun(@(pat)strcmp(purpose_part,pat), purpose_names);
if sum(ind) ~= 1
    fprintf('Error finding purpose type for string %s\n', purpose_part);
    keyboard;
end
event_struct.purpose = purpose_names{ind};

if isempty(fname_remainder) && strcmp(purpose_part, 'habituation')
    stimA_name = 'empty';
    stimB_name = 'empty';
    stimC_name = 'empty';
else
    %stimulus_names = fetchn(sl_behavior.VisualStimulusType,'stim_type');
    [stimA_name, fname_remainder] = strtok(fname_remainder(4:end),'_');
    [stimB_name, fname_remainder] = strtok(fname_remainder(5:end),'_');
    stimC_name = fname_remainder(5:end);
end

DJID = 0;
stims(1).arm = 'A';
stims(1).stim_type = stimA_name;
if strcmp(fetch1(sl_behavior.VisualStimulusType & sprintf('stim_type="%s"', stimA_name), 'needs_id'), 'T')
    %DJID = input('Datajoint ID for animal in arm A:');
    stims(1).stimulus_animal_id = DJID;
else
    stims(1).stimulus_animal_id = nan;
end

stims(2).arm = 'B';
stims(2).stim_type = stimB_name;
if strcmp(fetch1(sl_behavior.VisualStimulusType & sprintf('stim_type="%s"', stimB_name), 'needs_id'), 'T')
    %DJID = input('Datajoint ID for animal in arm B:');
    stims(2).stimulus_animal_id = DJID;
else
    stims(2).stimulus_animal_id = nan;
end

stims(3).arm = 'C';
stims(3).stim_type = stimC_name;
if strcmp(fetch1(sl_behavior.VisualStimulusType & sprintf('stim_type="%s"', stimC_name), 'needs_id'), 'T')
    %DJID = input('Datajoint ID for animal in arm C:');
    stims(3).stimulus_animal_id = DJID;
else
    stims(3).stimulus_animal_id = nan;
end

%look for recording and set date
D = dir(sprintf('%s%s%s%scamera_%d.MOV', ...
    basedir, filesep, fname, filesep, default_camera_serial_number));

if ~isempty(D)
    event_struct.recorded = 'T';
    date_vector = datevec(D.datenum);
    time_str = sprintf('%02d:%02d:%02d',...
        date_vector(4),date_vector(5),date_vector(6));
    event_struct.time = time_str;
else
    event_struct.recorded = 'F';
    event_struct.time = '00:00:00';
end
