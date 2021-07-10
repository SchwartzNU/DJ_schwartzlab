function R = collectDataAcrossSessions(sessions, P, stim_order)
session_ids = fetch(sessions, 'event_id');
L = length(session_ids);

ignore_fields = {'meanSpeed', ...
                'pause_frames', ...
                'pause_head_positions', ...
                'pause_widths', ...
                'Npauses', ...
                'first_pause_time'};
s = 1;
for i=1:L
    window_order = zeros(1,3);

    stims = fetch(sl.AnimalEventSocialBehaviorSessionStimulus & session_ids(i), 'stim_type', 'arm');
    
    for z=1:3
        ind = find(strcmp({stims.stim_type}, stim_order{z}));
        switch stims(ind).arm
            case 'A'
                window_order(z) = 1;
            case 'B'
                window_order(z) = 2;
            case 'C'
                window_order(z) = 3;
        end
    end
    
    curP = P;
    curP.window_order = window_order;
    
    trackingData = sl_behavior.BehaviorSessionTrackingData & session_ids(i);
    if trackingData.exists
        sessionData = behaviorSessionAnalysis(trackingData, 'test', curP);
        R.session_id = session_ids(i);
        fnames = fieldnames(sessionData);
        
        for f=1:length(fnames)
            if ~ismember(fnames{f}, ignore_fields)
                R.(fnames{f})(s,:) = sessionData.(fnames{f});                
            end
        end
        s=s+1;
    end
end
