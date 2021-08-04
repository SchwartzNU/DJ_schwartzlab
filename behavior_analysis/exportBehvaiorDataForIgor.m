function S = exportBehvaiorDataForIgor(R, paramName, fname)
S.exp_data = R.(paramName)(:,1)
S.control_data = mean([R.(paramName)(:,2), R.(paramName)(:,3)],2)

S.mean_exp = mean(S.exp_data);
S.sem_exp = std(S.exp_data) ./ sqrt(length(S.exp_data)-1);

S.mean_control = mean(S.control_data);
S.sem_control = std(S.control_data) ./ sqrt(length(S.control_data)-1);

S.p = signrank(S.exp_data, S.control_data);

exportStructToHDF5(S, [fname '.h5'], fname);