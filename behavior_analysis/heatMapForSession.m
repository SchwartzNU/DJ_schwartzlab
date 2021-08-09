function [] = heatMapForSession(session_id, analysis_end, param)
%analysis_end is in seconds
frameRate = 15; %Hz, TODO, load from calibration
X_edges = -20:3:20; %cm
Y_edges = -20:3:20; %cm
Nbins = length(X_edges);

inches_per_pixel = 0.022031; %TODO, load from calibration
recorded_center = [564, 426];
inner_radius = 3; %inches
outer_radius = 6.693; %inches
inch_to_cm = 2.54;

trackingData = fetch(sl_behavior.BehaviorSessionTrackingData & sprintf('event_id=%d', session_id), '*');

trialStart = find(~isnan(trackingData.head_position_arc),1);
trialEnd = trialStart + round(analysis_end*frameRate);

t = trackingData.time_axis(trialStart:trialEnd);
snoutX = trackingData.snout_x(trialStart:trialEnd);
snoutY = trackingData.snout_y(trialStart:trialEnd);

%make units of inches and zero at the center
snoutX = (snoutX - recorded_center(1)) * inches_per_pixel;
snoutY = (snoutY - recorded_center(2)) * inches_per_pixel;

R = sqrt(snoutX.^2 + snoutY.^2);
ind = R>inner_radius & R<outer_radius;
snoutX = snoutX(ind);
snoutY = snoutY(ind);

snoutX = snoutX * inch_to_cm;
snoutY = snoutY * inch_to_cm;

h = histogram2(snoutX,snoutY,X_edges,Y_edges);
S.xstart = mean(h.XBinEdges(1:2));
S.ystart = mean(h.YBinEdges(1:2));
S.xbin = h.BinWidth(1);
S.ybin = h.BinWidth(2);

%keyboard;
if strcmp(param,'snout')
    S.vals = h.Values ./ frameRate; %units of seconds   
elseif strcmp(param,'speed')
    speed_cm_per_s = [0; trackingData.body_speed(ind(1:end-1))].*inch_to_cm.*inches_per_pixel*frameRate;
    [N,~,~,binX,binY] = histcounts2(snoutX,snoutY,h.XBinEdges,h.YBinEdges);
    vals = zeros(Nbins,Nbins);
    for i=1:Nbins
        for j=1:Nbins
            vals(i,j) = nanmean(speed_cm_per_s(binX==i & binY==j));
        end
    end
    %speed_h.Data(:,1)
    S.vals = vals;
end

exportStructToHDF5(S,['heatMap_bySession_' param '.h5'],['sess_' num2str(session_id)]);

% paramVec = trackingData.(param);
% if trialEnd > length(paramVec)
%   disp(['Warning: ' num2str(analysis_end) ' after mouse exits chamber is past end of recording.']);
%   trialEnd = length(paramVec);
% end
% 
% paramVec = paramVec(trialStart:trialEnd);
% 
% binEdges = linspace(-pi,pi,Nbins+1);
% [histVals, bins] = histcounts(paramVec,binEdges,'Normalization','probability');
% histVals(end+1) = histVals(1);
% 
% S.bins = binEdges';
% S.vals = histVals';
% 
% exportStructToHDF5(S,['heatMap_bySession_' param '.h5'],['sess_' num2str(session_id)]);


