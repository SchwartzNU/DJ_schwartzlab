function [time_axis, trace_mean, trace_sem, trace_matrix] = meanForROI(roi_traces,id,asDFoverF)
if nargin < 3
    asDFoverF = true;
end

roi_traces_struct = fetch(roi_traces,'*');
n_epochs = length(roi_traces_struct);
time_points = size(roi_traces_struct(1).traces,2);
trace_matrix = zeros(n_epochs,time_points);
prot_name = fetch1(sln_symphony.ExperimentEpochBlock & roi_traces_struct(1),'protocol_name');
prot_name = sqlProtName2ProtName(prot_name);
example_epoch_params = fetch(aka.EpochParams(prot_name) * aka.BlockParams(prot_name) & roi_traces_struct(1), '*');
if isfield(example_epoch_params,'pre_time')
    time_axis = (1:time_points) - example_epoch_params.pre_time;
    pre_pts = time_axis < 0;
else
    time_axis = 1:time_points;
    pre_pts = 1:10; %10 ms
end

for i=1:n_epochs
    trace_matrix(i,:) = roi_traces_struct(i).traces(id,:);
    if asDFoverF
        baseline = mean(trace_matrix(i,pre_pts));
        trace_matrix(i,:) = (trace_matrix(i,:) - baseline) ./ baseline;
    end

end
trace_mean = mean(trace_matrix,1);
trace_sem = std(trace_matrix,[],1)./sqrt(n_epochs-1);
