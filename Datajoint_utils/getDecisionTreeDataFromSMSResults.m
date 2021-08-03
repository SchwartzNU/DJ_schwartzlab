function treeData = getDecisionTreeDataFromSMSResults(q)
%q is the query with the SMS results

sus_thres = 0.25; %fraction below peak to cuont in response

L = q.count;
R = fetchn(q,'result');
index_struct = fetch(q);

for i=1:L
    curR = R{i};
    %[~, size200_ind] = min(abs(curR.spotSize-200));
    [~, maxSizeInd] = max(curR.spikeRateStim_baselineSubtraced_mean);
    maxSizeInd = maxSizeInd(1);
    
    %try
        curPSTH = curR.sms_psth(maxSizeInd,:);
        
        baseline = mean(curPSTH(curR.psth_x<0));
        psth_baselineSub = curPSTH - baseline;
        
        full_baseline = mean(mean(curR.sms_psth(:,curR.psth_x<=0)));   
        sms_psth = curR.sms_psth - full_baseline;
        ONbins = sms_psth(:,curR.psth_x>0 & curR.psth_x<=1);
        OFFbins = sms_psth(:,curR.psth_x>1);
        ONbins_first200ms = sms_psth(:,curR.psth_x>0 & curR.psth_x<=.2);
        OFFbins_first200ms = sms_psth(:,curR.psth_x>1 & curR.psth_x<=1.2);

        treeData.ONsum(i) = sum(sum(ONbins));
        treeData.ONmax(i) = max(max(ONbins));
        treeData.ONmaxsum(i) = max(sum(ONbins,2)/100);
        treeData.ONmax_200ms(i) = max(sum(ONbins_first200ms,2)/20);        
        
        treeData.OFFsum(i) = sum(sum(OFFbins));
        treeData.OFFmax(i) = max(max(OFFbins));
        treeData.OFFmaxsum(i) = max(sum(OFFbins,2)/100);
        treeData.OFFmax_200ms(i) = max(sum(OFFbins_first200ms,2)/20);    
        
        treeData.ON_OFF_index(i) = (treeData.ONmax_200ms(i) - treeData.OFFmax_200ms(i))  / ...
            (treeData.ONmax(i) + treeData.OFFmax(i));
        
        
        stimInd = curR.psth_x>=0 & curR.psth_x<=1;
        psth_stim = psth_baselineSub(stimInd);        
        [ONpeak,ONpeak_ind] = max(psth_stim);
        ONpeak_ind = ONpeak_ind(1); %first one
        responseBins = sum(psth_stim(ONpeak_ind:end) >= sus_thres * ONpeak);
        treeData.responseFrac(i) = responseBins / length(psth_stim(ONpeak_ind:end));
        
        peak_300 = max(curPSTH(curR.psth_x>=0 & curR.psth_x<=0.3)) - baseline;
        mean_600 = mean(curPSTH(curR.psth_x>=0 & curR.psth_x<=0.6)) - baseline;
        
        treeData.ONpeak_ind(i) = ONpeak_ind;
        treeData.peak300ms(i) = peak_300;
        treeData.mean600ms(i) = mean_600;
        %treeData.ONrate_200(i) = curR.spikeRateStim_baselineSubtraced_mean(size200_ind);
        %treeData.OFFrate_200(i) = curR.spikeRatePost_baselineSubtraced_mean(size200_ind);
    %catch
    %    del(sl_greg.DatasetResult & index_struct(i));
    %end
end
