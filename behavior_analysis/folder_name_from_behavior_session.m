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

    stimA_ID = fetch1(stimuli & 'arm="A"','stimulus_animal_id');
    if isnan(stimA_ID), stimA_ID = ''; else stimA_ID = num2str(stimA_ID); end
    stimB_ID = fetch1(stimuli & 'arm="B"','stimulus_animal_id');
    if isnan(stimB_ID), stimB_ID = ''; else stimB_ID = num2str(stimB_ID); end
    stimC_ID = fetch1(stimuli & 'arm="C"','stimulus_animal_id');
    if isnan(stimC_ID), stimC_ID = ''; else stimC_ID = num2str(stimC_ID); end

    
    folder_name = sprintf('%s_(A)%s%s_(B)%s%s_(C)%s%s', ...
        folder_name, stimA_type, stimA_ID, stimB_type, stimB_ID, stimC_type, stimC_ID);
else
    fprintf('Stimuli not found for session %d\n', event_id);
    return;
end
