function S = exportBehvaiorDataForIgor_acrossTypes(R1, R2, paramName, fname)
R1_animals = R1.animal_id;
R1_data = R1.(paramName);
[R1_animals_sorted, sortInd] = sort(R1_animals);
S.R1_data = R1_data(sortInd);

R2_animals = R2.animal_id;
R2_data = R2.(paramName);
[R2_animals_sorted, sortInd] = sort(R2_animals);
S.R2_data = R2_data(sortInd);

S.mean_R1 = mean(S.R1_data);
S.sem_R1 = std(S.R1_data) ./ sqrt(length(S.R1_data)-1);

S.mean_R2 = mean(S.R2_data);
S.sem_R2 = std(S.R2_data) ./ sqrt(length(S.R2_data)-1);

if isequal(R1_animals_sorted, R2_animals_sorted)
    S.p = signrank(S.R1_data, S.R2_data);
else
    S.p = ranksum(S.R1_data, S.R2_data);
end

exportStructToHDF5(S, [fname '.h5'], fname);