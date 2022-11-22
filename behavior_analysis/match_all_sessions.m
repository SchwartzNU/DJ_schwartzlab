session_ids = fetchn(sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession, 'event_id');
N = length(session_ids)

for i=1:N
    session_ids(i)
    ind = find(event_id_map(:,2) == session_ids(i));
    old_id = event_id_map(ind,1)

    folder_name = matchSessionToBehaviorFolder(session_ids(i), old_id, '/Volumes/SchwartzLab/Behavior')
    pause;
end