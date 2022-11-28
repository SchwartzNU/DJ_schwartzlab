session_ids = fetchn(sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession, 'event_id');
N = length(session_ids)

session_match_table = table('Size',[N, 2],'VariableNames',{'event_id', 'folder_name'},'VariableTypes',{'uint16','cell'});

for i=1:N
    session_ids(i)
    thisSession = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('event_id=%d',session_ids(i));
    animal_id = fetch1(thisSession,'animal_id');
    recorded = fetch1(thisSession,'recorded');

    folder_name = matchSessionToBehaviorFolder(session_ids(i), '/Volumes/SchwartzLab/Behavior')
    session_match_table.event_id(i) = session_ids(i);
    if isempty(folder_name) || strcmp(folder_name,'none')
       session_match_table.folder_name(i) = {'not found'};
       if strcmp(recorded,'T')
        thisSession_struct = fetch(thisSession,'*')
        disp('not found and set to recorded = T');
        pause;
       end
    else
       session_match_table.folder_name(i) = {[num2str(animal_id) filesep folder_name]};
    end
end


