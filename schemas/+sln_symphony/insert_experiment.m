function k = insert_experiment(exp_name)
file_name = sprintf('%s.h5',exp_name);
sln_animal.add_eyes_for_deceased_animals();
k = insert(sln_symphony.Experiment,file_name);
%TODO: fix this so it returns the key...
