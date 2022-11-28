master_dir = '/Volumes/SchwartzLab/BehaviorMaster/';
behavior_dir = '/Volumes/SchwartzLab/Behavior/';
N = height(found_sessions_copy);

for i=1:N
    i
    new_folder_name = folder_name_from_behavior_session(found_sessions_copy.event_id(i));
    destination = ['''' root_dir new_folder_name filesep ''''];
    source = ['''' behavior_dir found_sessions_copy.folder_name{i} filesep ''''];
    command = sprintf('cp -r %s* %s', source, destination);
    unix(command);
end

