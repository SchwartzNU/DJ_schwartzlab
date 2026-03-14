function R = Ramp_analysis(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

%need to add the table definition from excel file
%here


for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * sln_symphony.SpikeTrain * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.BlockParams('Ramp') * aka.EpochParams('Ramp') ...
        & datasets_struct(d), '*');

    sample_rate = epochs_in_dataset(1).sample_rate;
    raw_data = vertcat(epochs_in_dataset.raw_data);
    slope = epochs_in_dataset(1).ramp_slope;
    increase_per_datapoint = slope / sample_rate;

    pre_time = epochs_in_dataset(1).pre_time / 1000;
    stim_time = epochs_in_dataset(1).stim_time / 1000;
    tail_time = epochs_in_dataset(1).tail_time / 1000;


    stimulus = zeros(size(raw_data,2), 1);
    stim_temp = [0 : (stim_time * sample_rate) - 1] * increase_per_datapoint;
    stimulus(pre_time * sample_rate : (pre_time + stim_time) * sample_rate - 1) = stim_temp;

    resting_vm = mean(raw_data(:, 1:pre_time * sample_rate), 2);

    mean_trace = mean(raw_data, 1);
    % figure;
    % subplot(2,1,1);
    % plot(raw_data');
    % subplot(2,1,2);
    % plot(stimulus);
    
    %% Tail time analysis
    tau_1 = nan(size(raw_data,1), 1);
    tau_2 = nan(size(raw_data,1), 1);

    if tail_time > 2
        fit_time = 2;
    else
        fit_time = tail_time-0.5;
    end

    for i = 1 : size(raw_data,1)

        post_stim_data = raw_data(i, ((pre_time + stim_time) * sample_rate) : ((pre_time + stim_time + 0.2) * sample_rate));

        [~, idx] = min(post_stim_data);
        idx = idx + (pre_time + stim_time) * sample_rate;
        y = raw_data(i, idx : (idx + (fit_time * sample_rate)));
        t = [0:length(y)-1] / sample_rate;

        ft = fittype( 'exp2' );
        opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
        opts.Algorithm = 'Levenberg-Marquardt';
        opts.Display = 'Off';
        opts.StartPoint = [-45.6079302262768 -0.000184482499308884 -19.8845504137804 0.000168607590000871];

        [xData, yData] = prepareCurveData(t, y);

        [fitresult, gof] = fit( xData, yData, ft, opts );
        tau_1(i) = -1/fitresult.b;
        tau_2(i) = -1/fitresult.d;
    end
    % fitresult.a
    % mean(tau_1) 
    % std(tau_1) 
    % fitresult.c
    % mean(tau_2) 
    % std(tau_2)
    
    min(mean(tau_1), mean(tau_2))
end
end