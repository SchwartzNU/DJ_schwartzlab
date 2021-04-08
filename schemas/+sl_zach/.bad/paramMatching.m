function [paramNames, paramCounts] = paramMatching()

files = dir('raw/*.mat');

paramNames = {};
paramCounts = zeros(0, numel(files));
nParams = 0;

ss = substruct('{}',{':'});

for n=1:numel(files)
    %% I/O
    s = load(sprintf('raw/%s',files(n).name));
    try
        params = horzcat(s.epochs(:).parameters);
    catch
        s1 = arrayfun(@(x) isempty(x.group), s.epochs);
        params = horzcat(s.epochs(s1).parameters);
        s.epochs(s1) = [];
        p = arrayfun(@(x) vertcat(s.epochs(x).parameters, s.epoch_groups(s.epochs(x).group).blocks(s.epochs(x).block).parameters), 1:numel(s.epochs),'uniformoutput',false);
        params = vertcat(params', p{:})';
    end
    
    %% Misc dropped parameters
    params(strcmp({params(:).Name},'pulseVector')) = []; %stored with channel 
    params(strcmp({params(:).Name},'shapeDataMatrix')) = []; %already determined how to hash this
    params(strcmp({params(:).Name},'voltages')) = []; %stored with channel
    params(strcmp({params(:).Name},'sessionId')) = []; %start time stored with epoch
    params(strcmp({params(:).Name},'varyingIntensityValues')) = []; %determined by contrast, ramp range
    params(strcmp({params(:).Name},'forcePrerender')) = []; %already solved
    
    
    %% ColorIntensity (deprecated) -- intensity multiplier for each color pattern, epoch based
    bc = strcmp({params(:).Name},'baseColor');
    c1 = arrayfun(@(x) x.Value(1), params(bc),'uniformoutput',false);
    c2 = arrayfun(@(x) x.Value(2), params(bc),'uniformoutput',false);
    params(bc) = [];
    params = horzcat(params, struct('Name','baseColor1','Value',c1,'Type','H5T_FLOAT'), struct('Name','baseColor2','Value',c2,'Type','H5T_FLOAT'));
    
    pr = strcmp({params(:).Name},'plotRange');
    p1 = arrayfun(@(x) x.Value(1), params(pr),'uniformoutput',false);
    p2 = arrayfun(@(x) x.Value(2), params(pr),'uniformoutput',false);
    params(pr) = [];
    params = horzcat(params, struct('Name','plotMin','Value',p1,'Type','H5T_FLOAT'), struct('Name','plotMax','Value',p2,'Type','H5T_FLOAT'));
    
    pr = strcmp({params(:).Name},'rampRange');
    p1 = arrayfun(@(x) x.Value(1), params(pr),'uniformoutput',false);
    p2 = arrayfun(@(x) x.Value(2), params(pr),'uniformoutput',false);
    params(pr) = [];
    params = horzcat(params, struct('Name','rampMin','Value',p1,'Type','H5T_FLOAT'), struct('Name','rampMax','Value',p2,'Type','H5T_FLOAT'));
    
    %% ColorIsoResponse -- old version
    pr = strcmp({params(:).Name},'contrastRange1');
    p1 = arrayfun(@(x) x.Value(1), params(pr),'uniformoutput',false);
    p2 = arrayfun(@(x) x.Value(2), params(pr),'uniformoutput',false);
    params(pr) = [];
    params = horzcat(params, struct('Name','contrastMin1','Value',p1,'Type','H5T_FLOAT'), struct('Name','contrastMax1','Value',p2,'Type','H5T_FLOAT'));
    
    pr = strcmp({params(:).Name},'contrastRange2');
    p1 = arrayfun(@(x) x.Value(1), params(pr),'uniformoutput',false);
    p2 = arrayfun(@(x) x.Value(2), params(pr),'uniformoutput',false);
    params(pr) = [];
    params = horzcat(params, struct('Name','contrastMin2','Value',p1,'Type','H5T_FLOAT'), struct('Name','contrastMax2','Value',p2,'Type','H5T_FLOAT'));
    
    
    %% DriftingTexture
    lowpass = strcmp({params(:).Name},'motionLowpassFilterParams');
    pb = arrayfun(@(x) x.Value(1), params(lowpass),'uniformoutput',false);
    sb = arrayfun(@(x) x.Value(2), params(lowpass),'uniformoutput',false);
    params(lowpass) = [];
    params = horzcat(params, struct('Name','motionLowpassFilterPassband','Value',pb,'Type','H5T_FLOAT'), struct('Name','motionLowpassFilterStopband','Value',sb,'Type','H5T_FLOAT'));
    
    %% OffsetMovingBar
    offsets = strcmp({params(:).Name},'offsetRange');
    omin = arrayfun(@(x) x.Value(1), params(offsets),'uniformoutput',false);
    omax = arrayfun(@(x) x.Value(2), params(offsets),'uniformoutput',false);
    params(offsets) = [];
    params = horzcat(params, struct('Name','offsetMin','Value',omin,'Type','H5T_FLOAT'), struct('Name','offsetMax','Value',omax,'Type','H5T_FLOAT'));
    
    offsets = strcmp({params(:).Name},'offsetSide');
    offsetV = {params(offsets).Value};
    is0 = cellfun(@(x) isa(x,'double') && x==0, offsetV);
    is1 = cellfun(@(x) isa(x,'double') && x==1, offsetV);
    offsetV(is0) = {'left'};
    offsetV(is1) = {'right'};
    [params(offsets).Value] = offsetV{:};
    
    angle = strcmp({params(:).Name},'angles');
    if any(angle)
        [params(angle).Value] = deal(subsref(arrayfun(@(x) numel(x.Value), params(angle),'uniformoutput',false), ss));
    end
    
    %% MovingObject
    params(strcmp({params(:).Name},'directions')) = [];
    params(strcmp({params(:).Name},'speeds')) = [];
    params(strcmp({params(:).Name},'offsets')) = [];
    params(strcmp({params(:).Name},'diameters')) = [];
    
    isD = strcmp({params(:).Name},'setDirections');
    d = params(isD);
    directions = zeros(3,length(d));
    dI = arrayfun(@(x) length(x.Value)==1, d);
    directions(:,dI) = vertcat([d(dI).Value],0.*[d(dI).Value], 360 - 360./[d(dI).Value]);
    
    dI = arrayfun(@(x) length(x.Value)==2, d);
    directions(:,dI) = vertcat(8*ones(1,nnz(dI)), cellfun(@(x) x(1), {d(dI).Value}), cellfun(@(x) x(2), {d(dI).Value}));
    
    dI = arrayfun(@(x) length(x.Value)==3, d);
    directions(:,dI) = vertcat(cellfun(@(x) x(3), {d(dI).Value}), cellfun(@(x) x(1), {d(dI).Value}), cellfun(@(x) x(2), {d(dI).Value}));
    
    dI = arrayfun(@(x) isempty(x.Value), d);
    directions(:,dI) = vertcat(ones(1,nnz(dI)), zeros(1,nnz(dI)), zeros(1,nnz(dI)));
    
    directions = num2cell(directions);
    
    params(isD) = [];
    params = horzcat(params, struct('Name','numberOfAngles','Value',directions(1,:),'Type','H5T_FLOAT'), struct('Name','angleMin','Value',directions(2,:),'Type','H5T_FLOAT'), struct('Name','angleMax','Value',directions(3,:),'Type','H5T_FLOAT'));
    
    % similar logic for speeds, offsets, diameters...
    isD = strcmp({params(:).Name},'setSpeeds');
    d = params(isD);
    directions = zeros(3,length(d));
    
    dI = arrayfun(@(x) isempty(x.Value), d);
    directions(:,dI) = vertcat(ones(1,nnz(dI)), zeros(1,nnz(dI)), zeros(1,nnz(dI)));
    
    dI = arrayfun(@(x) length(x.Value)==1, d);
    directions(:,dI) = vertcat(ones(1,nnz(dI)), [d(dI).Value], [d(dI).Value]);%vertcat([d(dI).Value],0.*[d(dI).Value], 360 - 360./[d(dI).Value]);
    
    dI = arrayfun(@(x) length(x.Value)==2, d);
    directions(:,dI) = vertcat(8*ones(1,nnz(dI)), cellfun(@(x) x(1), {d(dI).Value}), cellfun(@(x) x(2), {d(dI).Value}));
    
    dI = arrayfun(@(x) length(x.Value)==3, d);
    directions(:,dI) = vertcat(cellfun(@(x) x(3), {d(dI).Value}), cellfun(@(x) x(1), {d(dI).Value}), cellfun(@(x) x(2), {d(dI).Value}));
    directions = num2cell(directions);
    params(isD) = [];
    params = horzcat(params, struct('Name','numberOfSpeeds','Value',directions(1,:),'Type','H5T_FLOAT'), struct('Name','speedMin','Value',directions(2,:),'Type','H5T_FLOAT'), struct('Name','speedMax','Value',directions(3,:),'Type','H5T_FLOAT'));
    
    
    isD = strcmp({params(:).Name},'setDiameters');
    d = params(isD);
    directions = zeros(3,length(d));
    
    dI = arrayfun(@(x) isempty(x.Value), d);
    directions(:,dI) = vertcat(ones(1,nnz(dI)), zeros(1,nnz(dI)), zeros(1,nnz(dI)));
    
    dI = arrayfun(@(x) length(x.Value)==1, d);
    directions(:,dI) = vertcat(ones(1,nnz(dI)), [d(dI).Value], [d(dI).Value]);%vertcat([d(dI).Value],0.*[d(dI).Value], 360 - 360./[d(dI).Value]);
    
    dI = arrayfun(@(x) length(x.Value)==2, d);
    directions(:,dI) = vertcat(8*ones(1,nnz(dI)), cellfun(@(x) x(1), {d(dI).Value}), cellfun(@(x) x(2), {d(dI).Value}));
    
    dI = arrayfun(@(x) length(x.Value)==3, d);
    directions(:,dI) = vertcat(cellfun(@(x) x(3), {d(dI).Value}), cellfun(@(x) x(1), {d(dI).Value}), cellfun(@(x) x(2), {d(dI).Value}));
    directions = num2cell(directions);
    params(isD) = [];
    params = horzcat(params, struct('Name','numberOfDiameters','Value',directions(1,:),'Type','H5T_FLOAT'), struct('Name','dimaeterMin','Value',directions(2,:),'Type','H5T_FLOAT'), struct('Name','diameterMax','Value',directions(3,:),'Type','H5T_FLOAT'));
    

    isD = strcmp({params(:).Name},'setOffsets');
    d = params(isD);
    directions = zeros(3,length(d));
    
    dI = arrayfun(@(x) isempty(x.Value), d);
    directions(:,dI) = vertcat(ones(1,nnz(dI)), zeros(1,nnz(dI)), zeros(1,nnz(dI)));
    
    dI = arrayfun(@(x) length(x.Value)==1, d);
    directions(:,dI) = vertcat(ones(1,nnz(dI)), [d(dI).Value], [d(dI).Value]);%vertcat([d(dI).Value],0.*[d(dI).Value], 360 - 360./[d(dI).Value]);
    
    dI = arrayfun(@(x) length(x.Value)==2, d);
    directions(:,dI) = vertcat(17*ones(1,nnz(dI)), cellfun(@(x) abs(x(1)), {d(dI).Value}), cellfun(@(x) abs(x(2)), {d(dI).Value}));
    
    dI = arrayfun(@(x) length(x.Value)==3, d);
    directions(:,dI) = vertcat(cellfun(@(x) 2*x(3)+1, {d(dI).Value}), cellfun(@(x) abs(x(1)), {d(dI).Value}), cellfun(@(x) abs(x(2)), {d(dI).Value}));
    directions = num2cell(directions);
    params(isD) = [];
    params = horzcat(params, struct('Name','numberOfOffsets','Value',directions(1,:),'Type','H5T_FLOAT'), struct('Name','positiveOffsetMin','Value',directions(2,:),'Type','H5T_FLOAT'), struct('Name','positiveOffsetMax','Value',directions(3,:),'Type','H5T_FLOAT'));
    
    %% IsoResponseRamp
    %TODO: solve hashing for ramping?
    params(strcmp({params(:).Name},'rampPointsTime')) = [];
    params(strcmp({params(:).Name},'rampPointsIntensity')) = [];
    
    %% Aggregation
    [t, ~, c] = unique({params(:).Name});
%     sdm = find(strcmp(t,'shapeDataMatrix'));
%     t(sdm) = [];
%     c(c==sdm) = 0;
%     c(c>sdm) = c(c>sdm) - 1;
%     
%     volt = find(strcmp(t,'voltages'));
%     t(volt) = [];
%     c(c==volt) = 0;
%     c(c>volt) = c(c>volt) - 1;
%     
%     sid = find(strcmp(t,'sessionId'));
%     t(sid) = [];
%     c(c==sid) = 0;
%     c(c>sid) = c(c>sid) - 1;
    
    
    
    isString = find(arrayfun(@(x) isa(x.Value, 'char'), params));
    isNull = contains({params(isString).Value},'null');
    [params(isString(isNull)).Value] = deal(inf);
    
    k = arrayfun(@(x) numel(unique(cell2table({params(c==x).Value}'))), 1:numel(t));
    
    newP = cellfun(@(x) ~any(strcmp(x,paramNames)), t);
    if any(newP)
       paramNames = cat(1,paramNames, t(newP)');
       paramCounts = cat(1, paramCounts, zeros(nnz(newP), size(paramCounts,2)));
    end
    paramCounts(cellfun(@(x) find(strcmp(x, paramNames)), t), n) = k;
    
end
end

