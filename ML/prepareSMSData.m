function [D, labels] = prepareSMSData(q, splitTrainTest)
if nargin<2
    splitTrainTest = true;
end
%q is the querey with the SMS datasets
rng(1);

maxVal = 400;

if splitTrainTest
    N_of_each_in_test = 3;
else
    N_of_each_in_test = 0;
end

[tq,sq] = meshgrid(-.49:.01:2.5,logspace(log10(30),log10(1200),32));
[r, c] = size(tq);

q_struct = fetch(q, 'result');

L = q.count;
D = zeros(L,c,r);
labels = fetchn(q, 'cell_type');

labelsU = unique(labels);

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

% Rp = randperm(L);
% x_test = D(Rp(1:testN),:,:);
% x_train = D(Rp(testN+1:end),:,:);

%maxVal = max(D,[],'all');
D = D./maxVal;
D(D>1) = 1;

for i=1:length(labelsU)    
    ind = find(strcmp(labels,labelsU{i}));
    curLabel = deblank(labelsU{i});
    if exist(['train' filesep curLabel],'dir')
        system(sprintf('rm -rf "%s"', ['train' filesep curLabel]));
    end
    if exist(['test' filesep curLabel],'dir')
        system(sprintf('rm -rf "%s"', ['test' filesep curLabel]));
    end
    if splitTrainTest
        mkdir(['train' filesep curLabel]);
    end
    L = length(ind);
    if L > N_of_each_in_test
        if splitTrainTest
            mkdir(['test' filesep curLabel]);
        else
             mkdir(curLabel);
        end
        R = randperm(L);
        test_ind = R(1:N_of_each_in_test);
        train_ind = R(N_of_each_in_test+1:end);
        if splitTrainTest
            for j=1:length(test_ind)
                imwrite(squeeze(D(ind(test_ind(j)),:,:))', ...
                    sprintf('test%s%s%s%s%4.0d.jpg',filesep,curLabel,filesep,curLabel,j));
            end
            for j=1:length(train_ind)
                imwrite(squeeze(D(ind(train_ind(j)),:,:))', ...
                    sprintf('train%s%s%s%s%4.0d.jpg',filesep,curLabel,filesep,curLabel,j));
            end
        else
            for j=1:length(train_ind)
                imwrite(squeeze(D(ind(train_ind(j)),:,:))', ...
                    sprintf('%s%s%s%4.0d.jpg',curLabel,filesep,curLabel,j));
            end
        end
    else        
        for j=1:L
            imwrite(squeeze(D(ind(j),:,:))', ...
                sprintf('train%s%s%s%s%4.0d.jpg',filesep,curLabel,filesep,curLabel,j));
        end
    end
end




