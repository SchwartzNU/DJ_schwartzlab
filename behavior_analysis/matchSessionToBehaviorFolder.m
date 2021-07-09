function folder_name = matchSessionToBehaviorFolder(session_id, rootFolder)
folder_name = '';
thisSession = sl.AnimalEventSocialBehaviorSession & sprintf('event_id=%d',session_id);
animal_id = thisSession.fetchn('animal_id');
session_date = thisSession.fetchn('date');

temp = dir([rootFolder filesep num2str(animal_id)]);
session_folders = {temp.name};

ind = find(startsWith(session_folders, session_date));

if isempty(ind)
    disp(['session folder for session ' num2str(session_id) ' not found']);
elseif length(ind)>1
    disp(['multiple folder matches found for for session ' num2str(session_id)]);
    %TODO use other parts of folder name to figure it out
else
    folder_name = [rootFolder filesep num2str(animal_id) filesep session_folders{ind}];
end
