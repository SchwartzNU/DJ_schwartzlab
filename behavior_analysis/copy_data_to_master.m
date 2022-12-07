master_dir = '\\fsmresfiles.fsm.northwestern.edu\fsmresfiles\Ophthalmology\Research\SchwartzLab\BehaviorMaster\';
behavior_dir = '\\fsmresfiles.fsm.northwestern.edu\fsmresfiles\Ophthalmology\Research\SchwartzLab\Behavior\';
N = height(found_sessions_copy);

startPos = 768;
for i=startPos:N
    i
    new_folder_name = folder_name_from_behavior_session(found_sessions_copy.event_id(i));
    destination = ['''' master_dir new_folder_name filesep ''''];
    dest = [master_dir new_folder_name filesep];
    contents = dir(dest)
    if length(contents)==2 %empty
        source = ['''' behavior_dir found_sessions_copy.folder_name{i} filesep ''''];
        %command = sprintf('cp -r %s* %s', source, destination);
        command = sprintf('xcopy %s %s', source, destination);
        system(command);
    end
end

