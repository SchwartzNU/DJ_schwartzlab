function [bins, histVals] = rosePlotForSession(session_id, analysis_end, param)
%analysis_end is in seconds
frameRate = 15; %Hz, TODO, load from calibration
Nbins = 36;

trackingData = fetch(sl_behavior.BehaviorSessionTrackingData & sprintf('event_id=%d', session_id), '*');

trialStart = find(~isnan(trackingData.head_position_arc),1);
trialEnd = trialStart + round(analysis_end*frameRate);

paramVec = trackingData.(param);
if trialEnd > length(paramVec)
  disp(['Warning: ' num2str(analysis_end) ' after mouse exits chamber is past end of recording.']);
  trialEnd = length(paramVec);
end

paramVec = paramVec(trialStart:trialEnd);

binEdges = linspace(-pi,pi,Nbins+1);
[histVals, bins] = histcounts(paramVec,binEdges,'Normalization','probability');
histVals(end+1) = histVals(1);

S.bins = binEdges';
S.vals = histVals';

exportStructToHDF5(S,['rosePlot_bySession_' param '.h5'],['sess_' num2str(session_id)]);


