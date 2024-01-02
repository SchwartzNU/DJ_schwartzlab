function k = insert_experiment(exp_name)
file_name = sprintf('%s.h5',exp_name);
sln_animal.add_eyes_for_deceased_animals();
[k, success] = insert(sln_symphony.Experiment,file_name);
if success
    
    disp('Inserted experiment successfully');
    msgbox('Insert successful', 'Insert Done','help', 'modal');
else
    err_mess = sprintf('Insert experiment %s failed', file_name);
    msgbox(err_mess, 'Insert Fail','error', 'modal');
end

%TODO: fix this so it returns the key...
