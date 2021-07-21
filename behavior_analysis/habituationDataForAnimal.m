function R = habituationDataForAnimal(animal_id, P)

sessions = sl.AnimalEventSocialBehaviorSession & sprintf('animal_id=%d',animal_id) & 'purpose="habituation"';
sessions_with_data = sl_behavior.BehaviorSessionTrackingData & sessions;
trials = fetchn(sessions_with_data, 'event_id');

L = sessions_with_data.count;
for i=1:L
    i
    thisSession = sessions_with_data & sprintf('event_id=%d',trials(i));
    trialResult(i) = behaviorSessionAnalysis(thisSession, 'test', P);
    trialDate{i} = datetime(fetch1(sl.AnimalEventSocialBehaviorSession & sprintf('event_id=%d',trials(i)), 'date'));  
    trialDateNum(i) = datenum(trialDate{i});
    R.Npauses_per_min(i) = trialResult(i).Npauses_per_min;
    R.Ncontacts_per_min(i) = sum(trialResult(i).Ncontacts_per_min);
    R.median_pause_width(i) = median(trialResult(i).pause_widths);
    R.Nsqueaks_per_min(i) = trialResult(i).Nsqueaks_per_min;
end

[~, order] = sort(datenum(trialDateNum))
trialResult = trialResult(order);
trialDate = trialDate(order);

R.meanSpeed = [trialResult.meanSpeed];
R.Npauses = [trialResult.Npauses];
R.first_pause_time = [trialResult.first_pause_time];



