load behaviorParams
NonvirginLargeDS_cagemates =fetch(sl.AnimalEventSocialBehaviorSession & 'date<="2021-10-01"'&'date>="2021-08-01"'& 'purpose="cagemate_2_strangers"')
results_NonvirginLargeDS_cagemates = collectDataAcrossSessions(NonvirginLargeDS_cagemates, P, {'Female', 'Male', 'Male'})
exportBehvaiorDataForIgor(results_NonvirginLargeDS_cagemates, 'body_s', 'results_NonvirginLargeDS_1f2m_BodySeconds2')