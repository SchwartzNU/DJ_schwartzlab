%add_missing_SocialBehaviorStimulus_script
missing_entries = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession- sln_animal.SocialBehaviorSessionStimulus;
N = missing_entries.count
missing_entries_struct = fetch(missing_entries,'*');
for i=1:N
    i
    clear('stimA','stimB','stimC');
    stimA.event_id = missing_entries_struct(i).event_id;
    stimA.arm = 'A';
    stimB.event_id = missing_entries_struct(i).event_id;
    stimB.arm = 'B';
    stimC.event_id = missing_entries_struct(i).event_id;
    stimC.arm = 'C';

    missing_entries_struct(i)

    if strcmp(missing_entries_struct(i).purpose,'habituation')
        all_empty = true;
    else
        all_empty = false;
    end

    if all_empty
        stimA.stim_type = 'empty';
        stimB.stim_type = 'empty';
        stimC.stim_type = 'empty';
        stimA.stimulus_animal_id = nan;
        stimB.stimulus_animal_id = nan;
        stimC.stimulus_animal_id = nan;
    else

        stim_type = input('StimA: ', 's');
        stimA.stim_type = stim_type;
        if strcmp(fetch1(sl_behavior.VisualStimulusType & sprintf('stim_type="%s"',stim_type), 'needs_id'), 'T')
            stimA.stimulus_animal_id = input('DJID: ');
        else
            stimA.stimulus_animal_id = nan;
        end

        stim_type = input('StimB: ', 's');
        stimB.stim_type = stim_type;
        if strcmp(fetch1(sl_behavior.VisualStimulusType & sprintf('stim_type="%s"',stim_type), 'needs_id'), 'T')
            stimB.stimulus_animal_id = input('DJID: ');
        else
            stimB.stimulus_animal_id = nan;
        end

        stim_type = input('StimC: ', 's');
        stimC.stim_type = stim_type;
        if strcmp(fetch1(sl_behavior.VisualStimulusType & sprintf('stim_type="%s"',stim_type), 'needs_id'), 'T')
            stimC.stimulus_animal_id = input('DJID: ');
        else
            stimC.stimulus_animal_id = nan;
        end
    end
    try
        C = dj.conn;
        C.startTransaction;
        insert(sln_animal.SocialBehaviorSessionStimulus, stimA);
        insert(sln_animal.SocialBehaviorSessionStimulus, stimB);
        insert(sln_animal.SocialBehaviorSessionStimulus, stimC);
        C.commitTransaction
    catch ME
        C.cancelTransaction;
        fprintf('Insert error: %s\n', ME.message);
    end

end