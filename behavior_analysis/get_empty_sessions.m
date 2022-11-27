all_sessions = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession;
all_ids = fetchn(all_sessions,'event_id');
z=1;
for i=1:all_sessions.count
    stims = fetchn(sln_animal.SocialBehaviorSessionStimulus & sprintf('event_id=%d', all_ids(i)), 'stim_type');
    if all(strcmp(stims,'empty'))
        ev(z).event_id = all_ids(i);
        z=z+1;
    end
end

empty_sessions = all_sessions & ev;