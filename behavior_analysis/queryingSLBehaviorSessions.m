load behaviorParams
%attempt to sort based on subject sex
NonvirginLargeDS_cagemates =fetch(sl.AnimalEventSocialBehaviorSession & 'date<="2021-10-01"'&'date>="2021-08-01"'& 'sex="Female"'& 'purpose="cagemate_2_strangers"')
results_NonvirginLargeDS_cagemates = collectDataAcrossSessions(NonvirginLargeDS_cagemates, P,  {'cagemate', 'novel object', 'novel object'})
exportBehvaiorDataForIgor(results_NonvirginLargeDS_cagemates, 'body_s', 'results_NonvirginLargeDS_1f2m_BodySeconds2')

%attempt to sort based on stimulus sex
NonvirginLargeDS_1f2m =fetch(sl.AnimalEventSocialBehaviorSession & 'date<="2021-10-01"'&'date>="2021-08-01"'& 'purpose="cagemate_2_strangers"')
results_NonvirginLargeDS_1f2m = collectDataAcrossSessions(NonvirginLargeDS_cagemates, P, {'female', 'male', 'male'})
exportBehvaiorDataForIgor(results_NonvirginLargeDS_1f2m, 'body_s', 'results_NonvirginLargeDS_1f2m_BodySeconds2')