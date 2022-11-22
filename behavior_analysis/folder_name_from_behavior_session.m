function folder_name = folder_name_from_behavior_session(event_id)
folder_name = '';

q = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('event_id=%d', event_id);
if ~q.exists
    fprintf('SocialBehaviorSession event %d not found\n', event_id);
    return;
end

ev = fetch(q,'*');

folder_name = sprintf('%d%s%d_%s_%s_%s',...
    ev.animal_id,filesep,ev.event_id,ev.date,ev.animal_type_name,ev.purpose);

stimuli = sln_animal.SocialBehaviorSessionStimulus & q;
if stimuli.count == 3 
    stimA_type = fetch1(stimuli & 'arm="A"','stim_type');
    stimB_type = fetch1(stimuli & 'arm="B"','stim_type');
    stimC_type = fetch1(stimuli & 'arm="C"','stim_type');
    folder_name = sprintf('%s_(A)%s_(B)%s_(C)%s', ...
        folder_name, stimA_type, stimB_type, stimC_type);
else
    fprintf('Stimuli not found for session %d\n', event_id);
    return;
end
