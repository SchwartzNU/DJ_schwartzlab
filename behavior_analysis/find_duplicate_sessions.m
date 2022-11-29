%% find duplicates
clear('duplicate_sessions');

unique_folders = unique(found_sessions_copy.folder_name);

z=1;
for i=1:length(unique_folders)
    ind = find(strcmp(cellstr(found_sessions_copy.folder_name), unique_folders{i}));
    if length(ind)>1
        duplicate_sessions(z).folder_name = unique_folders{i};
        duplicate_sessions(z).event_ids = found_sessions_copy.event_id(ind);
        z=z+1;
    end
end

%% show them to deal with them
N = length(duplicate_sessions)
all_sessions = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession;
for i=1:N
    ids_struct = struct('event_id', num2cell(duplicate_sessions(i).event_ids));
    S = fetch(all_sessions & ids_struct, '*');
    if length(S)    > 1
        for s=1:length(S)
            S(s)
        end        
        duplicate_sessions(i).folder_name
        pause;
    end
end
