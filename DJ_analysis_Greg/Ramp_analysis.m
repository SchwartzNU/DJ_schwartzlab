function R = Ramp_analysis(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);



epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
    sln_symphony.ExperimentChannel * sln_symphony.SpikeTrain * ...
    sln_symphony.ExperimentEpochChannel * ...
    aka.BlockParams('Ramp') * aka.EpochParams('Ramp') ...
    & datasets_struct(2), '*');

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

figure;
subplot(2,1,1);
plot(raw_data');
subplot(2,1,2);
plot(stimulus);

tau_1 = nan(size(raw_data,1), 1);
tau_2 = nan(size(raw_data,1), 1);

for i = 1 : size(raw_data,1)

post_stim_data = raw_data(i, ((pre_time + stim_time) * sample_rate) : ((pre_time + stim_time + 0.2) * sample_rate));

[~, idx] = min(post_stim_data);
idx = idx + (pre_time + stim_time) * sample_rate;
y = raw_data(i, idx : (idx + (5 * sample_rate)));
t = [0:length(y)-1] / sample_rate * 1000;

ft = fittype( 'exp2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Algorithm = 'Levenberg-Marquardt';
opts.Display = 'Off';
opts.StartPoint = [-45.6079302262768 -0.000184482499308884 -19.8845504137804 0.000168607590000871];

% Fit model to data.
[xData, yData] = prepareCurveData( t, y );

[fitresult, gof] = fit( xData, yData, ft, opts );

x = [0:5000];
figure;
hold on;
plot(x, fitresult.a * exp(x * fitresult.b) + fitresult.c)
plot(x, fitresult.a * exp(x * fitresult.b) + fitresult.c * (exp(x * fitresult.d)))
plot(fitresult.c * (exp(x * fitresult.d)))
plot(t, y)

tau_1(i) = -1/fitresult.b;
tau_2(i) = -1/fitresult.d;
end

end