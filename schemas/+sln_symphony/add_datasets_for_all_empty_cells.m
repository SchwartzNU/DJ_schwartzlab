empty_cells = sln_symphony.ExperimentCell - sln_symphony.Dataset;
experiments_with_empty_cells = unique(fetchn(empty_cells, 'file_name'));

error_exps = {};

N = length(experiments_with_empty_cells)
for i=1:N
    fprintf('%d of %d', i, N);
    experiments_with_empty_cells{i}
    try
        sln_symphony.insert_all_datasets_for_experiment(experiments_with_empty_cells{i});
    catch ME
        error_exps = [error_exps; experiments_with_empty_cells{i}];
        disp(ME.message);
    end
end

