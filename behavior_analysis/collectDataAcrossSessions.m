function R = collectDataAcrossSessions(sessions, P, stim_order, animal_set)
if nargin < 4
    animal_set = [];
end

session_ids = fetch(sessions, 'event_id');
animal_ids = fetchn(sessions, 'animal_id');
L = length(session_ids);

ignore_fields = {...
    'pause_frames', ...
    'pause_head_positions', ...
    'pause_widths', ...
    'first_pause_time'};
s = 1;
for i=1:L    
    doAnalysis = true;
    animal_id = animal_ids(i);
    skipAnimal = false;
    if ~isempty(animal_set)
        if ~ismember(animal_id, animal_set)
            skipAnimal = true;
        end
    end
    
    if ~skipAnimal
        R.animal_id(s) = animal_id;
        
        if isfield(P, 'window_order')
            window_order = P.window_order;
        else
            window_order = zeros(1,3);
            
            stims = fetch(sl.AnimalEventSocialBehaviorSessionStimulus & session_ids(i), '*');
            %need to check sex for these ones
            purpose = fetch1(sl.AnimalEventSocialBehaviorSession & session_ids(i), 'purpose');
            if strcmp(purpose, 'female_2_males')
                for j=1:3
                    stims(j).sex = fetch1(sl.Animal & sprintf('animal_id=%d',stims(j).stimulus_animal_id), 'sex');
                end
            end
            
            %{stims.stim_type}
            
            try
                Rvec = randperm(2);
                randpick = false;
                for z=1:3
                    %need to check sex for these ones
                    purpose = fetch1(sl.AnimalEventSocialBehaviorSession & session_ids(i), 'purpose');
                    if strcmp(purpose, 'female_2_males')
                        ind = find(strcmp({stims.sex}, stim_order{z}));
                    else
                        ind = find(strcmp({stims.stim_type}, stim_order{z}));
                    end
                    
                    if length(ind)==2
                        if randpick
                            ind = ind(Rvec(2));
                        else
                            ind = ind(Rvec(1));
                            randpick = true;
                        end
                    end
                    switch stims(ind).arm
                        case 'A'
                            window_order(z) = 1;
                        case 'B'
                            window_order(z) = 2;
                        case 'C'
                            window_order(z) = 3;
                    end
                end
                if length(unique(window_order)) ~= 3 %duplicated window
                    sprintf('designated windows not found for session %d, skipping\n', session_ids(i).event_id);
                    doAnalysis = false;
                end
            catch
                sprintf('designated windows not found for session %d, skipping\n', session_ids(i).event_id);
                doAnalysis = false;
            end
            
        end
        curP = P;
        curP.window_order = window_order;
        
        trackingData = sl_behavior.BehaviorSessionTrackingData & session_ids(i);
        if trackingData.exists && doAnalysis
            sessionData = behaviorSessionAnalysis(trackingData, 'test', curP);
            R.session_id(s) = session_ids(i).event_id;
            fnames = fieldnames(sessionData);
            
            for f=1:length(fnames)
                if ~ismember(fnames{f}, ignore_fields)
                    R.(fnames{f})(s,:) = sessionData.(fnames{f});
                end
            end
            s=s+1;
        end
    end
end
