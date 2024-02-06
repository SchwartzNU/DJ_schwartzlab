function [uniqueVals, T] = tuningCurveByROI(allTraces, epochParamVals)
uniqueVals = sort(unique(epochParamVals),'ascend');
Nvals = length(uniqueVals);
NROI = size(allTraces{1},1);
ROI_tuning_mean = zeros(NROI,Nvals);
ROI_tuning_sem = zeros(NROI,Nvals);
OSI = zeros(NROI,1);
OSang = zeros(NROI,1);

for i=1:Nvals
    ind = find(epochParamVals==uniqueVals(i));
    L = length(ind);    
    tempVals = zeros(NROI,L);
    for j=1:L
        curTraces = allTraces{ind(j)};
        tempVals(:,j) = max(curTraces,[],2);
    end
    if L==1
        ROI_tuning_mean(:,i) = tempVals;
    else
        ROI_tuning_mean(:,i) = mean(tempVals,2);
        ROI_tuning_sem(:,i) = std(tempVals,[],2)./sqrt(L-1);
    end
end
    
for r=1:NROI
    R = computeDSIandOSI(uniqueVals, ROI_tuning_mean(r,:)');
    OSI(r) = R.OSI;
    OSang(r) = R.OSang;
end

T = table;
T.dFoverF_mean = ROI_tuning_mean;
T.dFoverF_sem = ROI_tuning_sem;
T.OSI = OSI;
T.OSang = OSang;