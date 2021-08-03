function [hitRate, faRate, pass_ind, missInd, faInd] = evaluateDecisionTreeNode(RGC_splits_table, allTypes, treeData, param, thres, tableVar)

valueByCell = cellfun(@(s)RGC_splits_table.(tableVar)(strcmp(s,RGC_splits_table.TypeName)), allTypes);

valueByParam = treeData.(param);


splitVal = valueByParam > thres;
splitVal = splitVal';

missInd = valueByCell & ~splitVal;
faInd = ~valueByCell & splitVal;

%get rid of unwanted / unknown types
okInd = valueByCell >= 0;

figure(2);
histogram(valueByParam(okInd),100);

missInd = missInd & okInd;
faInd = faInd & okInd;

pass_ind = splitVal;

valueByCell = valueByCell(okInd);
splitVal = splitVal(okInd);

%keyboard;
hitRate = sum(valueByCell & splitVal) / sum(valueByCell)
faRate = sum(~valueByCell & splitVal) / sum(~valueByCell)

