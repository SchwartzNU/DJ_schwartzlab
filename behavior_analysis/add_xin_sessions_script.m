%add_xin_sessions_script
animal_id_list = {'1939', ...
    '1941', ...
    '1942', ...
    '2042', ...
    '2043', ...
    '2104', ...
    '2105', ...
    '2106', ...
    '2031', ...
    '2032', ...
    '2033' ...
    };

basedir = '/Volumes/SchwartzLab/Behavior/';

C = dj.conn;
z=1;
for a=1:length(animal_id_list)
    cur_animal = animal_id_list{a};
    D = dir([basedir filesep cur_animal]);
    for i=1:length(D)
        if ~startsWith(D(i).name, '.')
            fname = sprintf('%s/%s', cur_animal, D(i).name);
            [event_struct, stims, event_id_from_fname] = reconstruct_behavior_event_from_folder(basedir, fname);
            event_id_from_fname
            event_struct

            %look to see if it is already there
            try
                matching_event = sln_animal.AnimalEvent & event_struct;
                if matching_event.exists
                    matched = true;
                else
                    matched = false;
                end
            catch
                matched = false;
            end
            if ~matched
                answer = input('Add session to database? [y|n]: ', 's');
                if strcmp(answer, 'y')
                    C.startTransaction;
                    try
                        sln_animal.add_event(event_struct,'SocialBehaviorSession',C);
                        this_event = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('animal_id=%s', cur_animal) & 'LIMIT 1 PER animal_id ORDER BY event_id DESC';
                        this_id = fetch1(this_event,'event_id');
                        for s=1:3
                            stim = stims(s);
                            stim.event_id = this_id;
                            insert(sln_animal.SocialBehaviorSessionStimulus,stim);
                        end
                        C.commitTransaction;
                        ev_id_match_table(z,1) = event_id_from_fname; %old id
                        ev_id_match_table(z,2) = this_id; %new id
                        z=z+1;
                    catch ME
                        fprintf('Insert failed: %s\n', ME.message);
                        C.cancelTransaction;
                    end
                end
            end
        end
    end
end