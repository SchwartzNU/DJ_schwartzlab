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
    R.median_pause_width(i) = median(trialResult(i).pause_widths);
end

[~, order] = sort(datenum(trialDateNum))
trialResult = trialResult(order);
trialDate = trialDate(order);

R.meanSpeed = [trialResult.meanSpeed];
R.Npauses = [trialResult.Npauses];
R.first_pause_time = [trialResult.first_pause_time];



