function R = GLUT1_data_for_all_animals()
animal_query = sln_imquant.GLUT1_by_animal;
animal_ids = fetchn(animal_query,'animal_id');
n_cells = fetchn(animal_query,'n_cells_total');

R.ex_vivo_dark_mean_gfp_neg = [];
R.ex_vivo_dark_mean_gfp_pos = [];
R.ex_vivo_light_mean_gfp_neg = [];
R.ex_vivo_light_mean_gfp_pos = [];

R.animal_id_vec = [];
R.age_vec = [];
R.sex_vec = [];
R.N_vec = [];
R.genotype_vec = [];

L = length(animal_ids);
for i=1:L
    try
        animal_results = sln_imquant.plot_GLUT1_data_for_animal(animal_ids(i));
    catch
        animal_results = [];
    end
    if ~isempty(animal_results)
        if strcmp(animal_results.light_condition_name{1}, 'checkerboard flicker') && ...
                height(animal_results) == 4 && ...
                strcmp(animal_results.drug_condition_name{1},'control')
            %animal_results
            R.animal_id_vec = [R.animal_id_vec; animal_ids(i)];
            R.age_vec = [R.age_vec; animal_results.age_at_exp(1)];
            R.N_vec = [R.N_vec; n_cells(i)];
            if strcmp(animal_results.sex,'Male')
                R.sex_vec = [R.sex_vec; 1]; %1 for male
            else
                R.sex_vec = [R.sex_vec; 0]; %0 for female
            end
            if strcmp(animal_results.genotype_string,'Trarg1(Tusc5-eGFP/Tusc5-eGFP)')
                R.genotype_vec = [R.genotype_vec; 0]; %0 for homo
            elseif strcmp(animal_results.genotype_string,'Trarg1(Tusc5-eGFP/WT)')
                R.genotype_vec = [R.genotype_vec; 1]; %1 for het
            else
                R.genotype_vec = [R.genotype_vec; 1]; %-1 for anything else
            end

            R.ex_vivo_dark_mean_gfp_neg = [R.ex_vivo_dark_mean_gfp_neg; animal_results.glut1_ratio_mean(3)];
            R.ex_vivo_dark_mean_gfp_pos = [R.ex_vivo_dark_mean_gfp_pos; animal_results.glut1_ratio_mean(4)];
            R.ex_vivo_light_mean_gfp_neg = [R.ex_vivo_light_mean_gfp_neg; animal_results.glut1_ratio_mean(1)];
            R.ex_vivo_light_mean_gfp_pos = [R.ex_vivo_light_mean_gfp_pos; animal_results.glut1_ratio_mean(2)];
        end
    end
end

