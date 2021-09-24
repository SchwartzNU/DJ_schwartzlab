function R = MovingBar_speedAnalysis_spikes(cellq, pipeline, P)
R = []; %will be struct. error if isempty

dataset_result_key.dataset_func_name = 'MovingBar_spike_analysis';
dataset_result_key.pipeline_name = pipeline;
dataset_result_key.cell_id = fetch1(cellq,'cell_id');

dataset_res = getStoredResult('Dataset', dataset_result_key);
dataset_results = fetchn(dataset_res, 'result');

resultsToStore = {'barSpeed',...
    'maxFR_mean',...
    'maxFR_sem',...
    };

for i=1:length(dataset_results)
    curR = dataset_results{i};
    for r=1:length(resultsToStore)
        R.(resultsToStore{r})(i) = curR.(resultsToStore{r});
    end
end

[speeds_sorted, order] = sort(R.barSpeed);

for r=1:length(resultsToStore)
    R.(resultsToStore{r}) = R.(resultsToStore{r})(order);
end