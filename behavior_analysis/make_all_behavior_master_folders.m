root_dir = '/Volumes/SchwartzLab/BehaviorMaster/';
all_sessions_recorded = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & 'recorded="T"';
all_ids = fetchn(all_sessions_recorded, 'event_id');
for i=1:length(all_ids)
    folder_name = folder_name_from_behavior_session(all_ids(i));
    mkdir([root_dir folder_name]);
end