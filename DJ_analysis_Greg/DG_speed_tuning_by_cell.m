function R = DG_speed_tuning_by_cell(data_group, params)

R = struct;
cells = sln_cell.Cell * sln_symphony.ExperimentCell * sln_cell.CellName & proj(data_group);
cells_struct = fetch(cells,'cell_name');
N_cells = cells.count;
R = sln_results.table_definition_from_template('DG_speed_tuning_by_cell',N_cells);

for c=1:N_cells
    tic;
    fprintf('Processing %d of %d, %s\n', c, N_cells, cells_struct(c).cell_name);

    results_for_cell = sln_results.DatasetDriftingGratingsCC & cells_struct(c);
    %epochs_in_dataset_struct = fetch(epochs_in_dataset,'*');

    N_results = results_for_cell.count;

    if N_results == 0
        fprintf('No stored results for cell: %s\n', cells_struct(c).cell_name);
    end

    R.cell_name(c) = cells_struct(c).cell_name;
    R.cell_unid(c) = cells_struct(c).cell_unid;

    result_struct = fetch(results_for_cell, ...
        'cycle_avg_amplitude', ...
        'cycle_avg_peak_neg', ...
        'cycle_avg_peak_pos', ...
        'speed_by_condition' ...
        );
    
    z=1;
    speed_vec = [];
    max_amp = [];
    mean_amp = [];
    min_neg = [];
    mean_neg = [];
    max_pos = [];
    mean_pos = [];
    for i=1:N_results
        cur_results = result_struct(i);
        speed_list = unique(cur_results.speed_by_condition);
        for j=1:length(speed_list)
            ind = cur_results.speed_by_condition == speed_list(j);
            speed_vec(z) = speed_list(j);
            max_amp(z) = max(cur_results.cycle_avg_amplitude(ind));
            mean_amp(z) = mean(cur_results.cycle_avg_amplitude(ind));
            min_neg(z) = min(cur_results.cycle_avg_peak_neg(ind));
            mean_neg(z) = mean(cur_results.cycle_avg_peak_neg(ind));
            max_pos(z) = max(cur_results.cycle_avg_peak_pos(ind));
            mean_pos(z) = mean(cur_results.cycle_avg_peak_pos(ind));        
            z=z+1;
        end
    end

    [speeds_unique, unique_ind] = unique(speed_vec);
    if length(speeds_unique) < length(speed_vec)
        disp('Warning: duplicate data at a single speed. Taking first entry');
        max_amp = max_amp(unique_ind);
        mean_amp = mean_amp(unique_ind);
        min_neg = min_neg(unique_ind);
        mean_neg = mean_neg(unique_ind);
        max_pos = max_pos(unique_ind);
        mean_pos = mean_pos(unique_ind);
        [speeds_sorted, order] = sort(speeds_unique, 'ascend');
    else
        [speeds_sorted, order] = sort(speed_vec, 'ascend');
    end
    
    max_amp = max_amp(order);
    mean_amp = mean_amp(order);
    min_neg = min_neg(order);
    mean_neg = mean_neg(order);
    max_pos = max_pos(order);
    mean_pos = mean_pos(order);

    % %set table variables
    R.speeds(c) = {speeds_sorted};
    R.max_cycle_avg_amplitude(c) = {max_amp};
    R.mean_cycle_avg_amplitude(c) = {mean_amp};
    R.min_cycle_avg_peak_neg(c) = {min_neg};
    R.mean_cycle_avg_peak_neg(c) = {mean_neg};
    R.max_cycle_avg_peak_pos(c) = {max_pos};
    R.mean_cycle_avg_peak_pos(c) = {mean_pos};

    fprintf('Elapsed time = %d seconds\n', round(toc));
end