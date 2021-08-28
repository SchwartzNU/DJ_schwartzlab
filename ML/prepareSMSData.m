function [D, labels, x_test, x_train] = prepareSMSData(q)
%q is the querey with the SMS datasets

testFrac = .15;

[tq,sq] = meshgrid(-1:.01:2.5,logspace(log10(30),log10(1200),32));
[r, c] = size(tq);

q_struct = fetch(q, 'result');

L = q.count;
D = zeros(L,c,r);
labels = fetchn(q, 'cell_type');

testN = round(testFrac*L);

for i=1:L
    R = q_struct(i).result;
    measured_times = {R.psth_x};
    minT = cellfun(@min,measured_times);
    maxT = cellfun(@max,measured_times);
    D(i,:,:) = permute(reshape(...
        rebinData(...
        {R.sms_psth},...
        {R.spotSize'},...
        sq(:)',...
        [minT' maxT'],...
        tq(:),...
        .01...
        )...
        , [], r, c),[3,2,1]);    
end

Rp = randperm(L);
x_test = D(Rp(1:testN),:,:);
x_train = D(Rp(testN+1:end),:,:);






