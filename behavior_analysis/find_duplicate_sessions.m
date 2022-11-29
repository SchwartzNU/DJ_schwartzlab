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

%% remove orphan folders from BehaviorMaster
master_dir = '/Volumes/SchwartzLab/BehaviorMaster/';
all_sessions = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession;
D = dir(master_dir);
for i=1:length(D)
    cur_animal = D(i).name;
    if ~startsWith(cur_animal, '.')
       D_inner = dir([master_dir cur_animal]);
       for j=1:length(D_inner)
           folder_name = D_inner(j).name;
           if ~startsWith(folder_name, '.')
                id = str2double(extractBefore(folder_name,'_'));
                q = all_sessions & sprintf('event_id=%d', id);
                if ~q.exists
                    fname = [master_dir cur_animal filesep folder_name];
                    fprintf('Removing directory %s\n', fname);
                    %answer = input(sprintf('Remove directory %s? [y|n]', fname), 's');
%                    if strcmp(answer, 'y')
                        rmdir(fname, 's');                        
                        %pause;
%                    end
                end
           end
       end
    end
end






