function folder_name = matchSessionToBehaviorFolder(session_id, old_id, rootFolder)
folder_name = '';
%thisSession = sl.AnimalEventSocialBehaviorSession & sprintf('event_id=%d',session_id);
thisSession = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('event_id=%d',session_id)
animal_id = thisSession.fetchn('animal_id')
session_date = thisSession.fetchn('date');

temp = dir([rootFolder filesep num2str(animal_id)]);
session_folders = {temp.name};

%new naming convention puts session ID first
%ind = find(startsWith(session_folders, sprintf('%d_',session_id)));
ind = find(startsWith(session_folders, sprintf('%d_',old_id)));
if length(ind)==1
    folder_name = [rootFolder filesep num2str(animal_id) filesep session_folders{ind}];
    return;
end

ind = find(startsWith(session_folders, session_date));

if isempty(ind)
    disp(['session folder for session ' num2str(session_id) ' not found']);
elseif length(ind)>1
    stims = sl.AnimalEventSocialBehaviorSessionStimulus & thisSession;
    stims_stuct = fetch(stims, '*');
    stim_str = [];
    
    for i=1:length(stims_stuct)
        stimType = strrep(stims_stuct(i).stim_type, ' ', '_');
        stimulus_animal_id = stims_stuct(i).stimulus_animal_id;
        if strcmp(stimType, 'single_pup')
            stimType = 'pup'; %HACK for inconsistent naming
        end
        if ~isnan(stimulus_animal_id)
            stimType = num2str(stimulus_animal_id);
        end        
        stim_str = [stim_str, sprintf('(%s)%s_', stims_stuct(i).arm, stimType)];
    end
    stim_str = stim_str(1:end-1);
    
    if strcmp(stim_str, '(A)empty_(B)empty_(C)empty')
        stim_str = 'habituation'; %HACK for inconsistent naming
    end
        
    for i=1:length(ind)
        curFolder = session_folders{ind(i)}
        stim_str
        if endsWith(curFolder, stim_str)
            folder_name = [rootFolder filesep num2str(animal_id) filesep session_folders{ind(i)}];
            return;
        end
    end
    
else
    folder_name = [rootFolder filesep num2str(animal_id) filesep session_folders{ind}];
end
