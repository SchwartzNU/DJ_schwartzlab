function R = MovingBar_speedAnalysis_currents(cellq, pipeline, P)
R = []; %will be struct. error if isempty

dataset_result_key.dataset_func_name = 'MovingBar_current_analysis';
dataset_result_key.pipeline_name = pipeline;
dataset_result_key.cell_id = fetch1(cellq,'cell_id');

dataset_res = getStoredResult('Dataset', dataset_result_key);
dataset_results = fetchn(dataset_res, 'result');

resultsToStore = {'barSpeed',...
    'maxCurrent_mean',...
    'maxCurrent_sem',...
    'ampHoldSignal'
    };

e_count = 1;
i_count = 1;
for i=1:length(dataset_results)
    curR = dataset_results{i};
    if curR.ampHoldSignal < 0
        for r=1:length(resultsToStore)
            R.(['exc_' resultsToStore{r}])(e_count) = curR.(resultsToStore{r});
        end
        e_count = e_count + 1;
    else
        for r=1:length(resultsToStore)
            R.(['inh_' resultsToStore{r}])(i_count) = curR.(resultsToStore{r});
        end
        i_count = i_count + 1;
    end
end


[speeds_sorted, order] = sort(R.exc_barSpeed);

R.exc_barSpeed = speeds_sorted;
R.exc_maxCurrent_mean = R.exc_maxCurrent_mean(order);
R.exc_maxCurrent_sem = R.exc_maxCurrent_sem(order);
R.exc_ampHoldSignal = R.exc_ampHoldSignal(order);

[speeds_sorted, order] = sort(R.inh_barSpeed);
R.inh_barSpeed = speeds_sorted;
R.inh_maxCurrent_mean = R.inh_maxCurrent_mean(order);
R.inh_maxCurrent_sem = R.inh_maxCurrent_sem(order);