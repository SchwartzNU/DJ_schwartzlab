function [] = insert_experiment(exp_name)
file_name = sprintf('%s.h5',exp_name);
sln_animal.add_eyes_for_deceased_animals();
insert(sln_symphony.Experiment,file_name);
