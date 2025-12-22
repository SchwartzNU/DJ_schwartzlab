%{
# DatasetPairedSpotsNLMapCC
-> sln_results.DatasetPairedSpotsCC
---
single_spots_resp_map : longblob     # rasterized single-spot responses (matrix)
single_spots_map_x    : longblob     # x vector for single_spots_resp_map
single_spots_map_y    : longblob     # y vector for single_spots_resp_map
paired_spots_distance : longblob     # vector of measured pair distances
paired_spots_nli      : longblob     # NLI values for each paired entry
predicted_resp        : longblob     # predicted responses (RA+RB) per paired entry
actual_resp           : longblob     # actual paired responses (Rp) per paired entry
distance_vals             : longblob  # unique integer distance bins (vector)
paired_spots_nli_maps     : longblob  # cell array of 2D maps (one per distance)
paired_spots_maps_x       : longblob  # cell array of x vectors (per map)
paired_spots_maps_y       : longblob  # cell array of y vectors (per map)
analysis_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
git_tag : varchar(128) # git tag of current version of DJ_ROOT folder
%}

classdef DatasetPairedSpotsNLMapCC < dj.Computed
    properties
        keySource = sln_results.DatasetPairedSpotsCC;
    end
    methods(Access=protected)
        function makeTuples(self, key)
            disp('populating NL map')
            R = fetch(sln_results.DatasetPairedSpotsCC & key, '*');
            Ncontrasts = length(R.contrasts);

            for c=1:Ncontrasts
                single_spot_struct = R.single_spot_data{c};

                single_fn = fieldnames(single_spot_struct);
                nSingle = numel(single_fn);
                single_coords = nan(nSingle,2);
                for ii = 1:nSingle
                    single_coords(ii,:) = parse_single_fieldname(single_fn{ii});
                end

                % Grid extents and rasterization (integer intrinsic coords)
                spot_r = R.spot_size / 2;
                minx = floor(min(single_coords(:,1) - spot_r));
                maxx = ceil(max(single_coords(:,1) + spot_r));
                miny = floor(min(single_coords(:,2) - spot_r));
                maxy = ceil(max(single_coords(:,2) + spot_r));

                xv = minx:maxx;
                yv = miny:maxy;
                [X, Y] = meshgrid(xv, yv);   % rows correspond to y

                accum = zeros(size(X));
                count = zeros(size(X));

                for i = 1:nSingle
                    x0 = single_coords(i,1);
                    y0 = single_coords(i,2);
                    respVal = single_spot_struct.(single_fn{i}).resp;
                    if ~isscalar(respVal)
                        respVal = mean(respVal(:),'omitnan');
                    end
                    mask = (X - x0).^2 + (Y - y0).^2 <= spot_r^2;
                    accum(mask) = accum(mask) + double(respVal);
                    count(mask) = count(mask) + 1;
                end

                map = nan(size(accum));
                idx = count > 0;
                map(idx) = accum(idx) ./ count(idx);

                key.single_spots_resp_map{c} = map;
                key.single_spots_map_x{c} = xv;
                key.single_spots_map_y{c} = yv;

                % now the paired spots data
                paired_spots_struct = R.paired_spot_data{c};
                fn = fieldnames(paired_spots_struct);
                m = numel(fn);
                dists = nan(m,1);

                for i = 1:m
                    s = paired_spots_struct.(fn{i});
                    if isfield(s, 'distance')
                        val = s.distance;
                        if ~isscalar(val)
                            val = mean(val(:),'omitnan');
                        end
                        dists(i) = double(val);
                    else
                        dists(i) = NaN;
                    end
                end

                key.paired_spots_distance{c} = dists;

                nli_key = compute_paired_nli(single_spot_struct, paired_spots_struct);
                fnames_nli = fieldnames(nli_key);
                for f=1:length(fnames_nli)
                    key.(fnames_nli{f}){c} = nli_key.(fnames_nli{f});
                end
                
                maps_key = build_paired_nli_maps(single_spot_struct, paired_spots_struct);
                fnames_maps = fieldnames(maps_key);
                for f=1:length(fnames_maps)
                    key.(fnames_maps{f}){c} = maps_key.(fnames_maps{f});
                end             
            end
            %insert part
            C = dj.conn;
            cur_user = C.user;

            %check git status
            cur_dir = pwd;
            cd(getenv('DJ_ROOT'));
            try
                [~, msg] = system('git status --porcelain');
                if ~isempty(msg)
                    error('You have locally modified files in %s. Please commit them first.', getenv('DJ_ROOT'));
                end
                tag_name = sprintf('%s_%s', cur_user, datestr(datetime('now'), 'yyyy-mmmm-dd-HH-MM-SS'));
                sprintf('git tag %s', tag_name)
                system(sprintf('git tag %s', tag_name));
            catch ME
                cd(cur_dir);
                rethrow(ME);
            end

            key.git_tag = tag_name;
            try
                insert(self, key, 'REPLACE');
            catch 
                disp('insert error');
            end
        end
    end
end

%% compute_paired_nli (REPLACE existing version)
function key = compute_paired_nli(single_spot_struct, paired_spots_struct)
dist_tol = 20;

fn_pair = fieldnames(paired_spots_struct);
m = numel(fn_pair);
nli = nan(m,1);
pred = nan(m,1);
actual = nan(m,1);

% Precompute single-spot centers and a name->index map for exact lookup
single_fn = fieldnames(single_spot_struct);
ns = numel(single_fn);
single_coords = nan(ns,2);
for ii = 1:ns
    single_coords(ii,:) = parse_single_fieldname(single_fn{ii});
end
fn_map = containers.Map(single_fn, 1:ns);

for i = 1:m
    s = paired_spots_struct.(fn_pair{i});

    % actual paired response Rp
    if isfield(s,'resp')
        Rp = single_spots_to_scalar(s.resp);
    else
        Rp = NaN;
    end

    RA = NaN; RB = NaN;

    %Parse pair name to coords and try exact constructed names (if your naming scheme allows)
    if isnan(RA) || isnan(RB)
        [coordA, coordB] = parse_pair_fieldname(fn_pair{i});
        % try to build single-fieldname string if you have a builder
        nameA = build_single_fieldname(coordA); %#ok<NASGU>
        if isKey(fn_map, nameA)
            RA = single_spots_to_scalar(single_spot_struct.(nameA).resp);
        else
            %if empty find nearest
            [idx, dist, matchedName, resp] = find_nearest_spot_progressive(coordA, single_coords, single_fn, single_spot_struct, dist_tol);
            if isempty(matchedName)
                RA = NaN;
            else
                RA = single_spots_to_scalar(single_spot_struct.(matchedName).resp);
            end
        end
        nameB = build_single_fieldname(coordB); %#ok<NASGU>
        if isKey(fn_map, nameB)
            RB = single_spots_to_scalar(single_spot_struct.(nameB).resp);
        else
            %if empty find nearest
            [idx, dist, matchedName, resp] = find_nearest_spot_progressive(coordB, single_coords, single_fn, single_spot_struct, dist_tol);
            if isempty(matchedName)
                RB = NaN;
            else
                RB = single_spots_to_scalar(single_spot_struct.(matchedName).resp);
            end
        end
    end

    % ensure scalars
    RA = single_spots_to_scalar(RA);
    RB = single_spots_to_scalar(RB);

    pred(i) = RA + RB;
    actual(i) = Rp;

    denom = pred(i);
    if isempty(denom) || isnan(denom) || denom == 0 || isnan(Rp)
        nli(i) = NaN;
    else
        nli(i) = (Rp - denom) / denom;
    end
end

key.paired_spots_nli = nli;
key.predicted_resp = pred;
key.actual_resp = actual;

nanIdx = find(isnan(key.predicted_resp));
fprintf('Predicted NaNs: %d / %d\n', numel(nanIdx), numel(key.predicted_resp));
for k = 1:min(10,numel(nanIdx))
    i = nanIdx(k);
    fn = fn_pair{i};
    % print Rp, RA, RB if available in the paired struct
    s = paired_spots_struct.(fn);
    Rp = single_spots_to_scalar(getfield_ifexists(s,'resp'));
    fprintf('%d: %s  Rp=%g  RA=%g  RB=%g\n', i, fn, Rp, RA, RB);
end

% helper (place near top of file or inline)
    function v = getfield_ifexists(s,varargin)
        v = NaN;
        try
            f = s;
            for t = 1:numel(varargin)
                if isfield(f,varargin{t})
                    f = f.(varargin{t});
                else
                    v = NaN; return
                end
            end
            v = f;
        catch
            v = NaN;
        end
    end
end

%% build_paired_nli_maps (REPLACE existing version)
function key = build_paired_nli_maps(single_spot_struct, paired_spots_struct)
fn = fieldnames(paired_spots_struct);
m = numel(fn);
centers = nan(m,2);
distances = nan(m,1);
nli_vals = nan(m,1);

dist_tol = 20;

% local scalar helper
    function s = to_scalar(x)
        if isempty(x), s = NaN; return; end
        if isscalar(x), s = double(x); else s = double(mean(x(:),'omitnan')); end
    end

% Precompute single spot data for fallback lookups
single_fn = fieldnames(single_spot_struct);
ns = numel(single_fn);
single_coords = nan(ns,2);
for ii = 1:ns, single_coords(ii,:) = parse_single_fieldname(single_fn{ii}); end
single_coords = round(single_coords); % NSx2 integer single-spot coords

% build a name->index map for fast exact lookup
fn_map = containers.Map(single_fn, 1:ns);

for i = 1:m
    s = paired_spots_struct.(fn{i});

    % distance
    if isfield(s,'distance')
        distances(i) = to_scalar(s.distance);
    else
        distances(i) = NaN;
    end

    % center: prefer stored center; fallback to parsed coords from fieldname
    if isfield(s,'center') && numel(s.center)==2 && all(~isnan(s.center))
        centers(i,:) = double(s.center(:)');
    else
        [coordA, coordB] = parse_pair_fieldname(fn{i});
        if ~any(isnan(coordA)) && ~any(isnan(coordB))
            centers(i,:) = mean([coordA; coordB],1);
        else
            centers(i,:) = [NaN NaN];
        end
    end

    % --- determine Rp, RA, RB ---
    Rp = NaN; RA = NaN; RB = NaN;
    if isfield(s,'resp'), Rp = to_scalar(s.resp); end
    if isfield(s,'A') && isfield(s.A,'resp'), RA = to_scalar(s.A.resp); end
    if isfield(s,'B') && isfield(s.B,'resp'), RB = to_scalar(s.B.resp); end

    % If RA/RB still NaN, try exact name match or nearest single spot fallback
    if isnan(RA) || isnan(RB)
        [coordA, coordB] = parse_pair_fieldname(fn{i});
        nameA = build_single_fieldname(coordA);
        if isKey(fn_map, nameA)
            RA = single_spots_to_scalar(single_spot_struct.(nameA).resp);
        else
            [idx, dist, matchedName, resp] = find_nearest_spot_progressive(coordA, single_coords, single_fn, single_spot_struct, dist_tol);
            if ~isempty(matchedName)
                RA = single_spots_to_scalar(single_spot_struct.(matchedName).resp);
            end
        end

        nameB = build_single_fieldname(coordB);
        if isKey(fn_map, nameB)
            RB = single_spots_to_scalar(single_spot_struct.(nameB).resp);
        else
            [idx, dist, matchedName, resp] = find_nearest_spot_progressive(coordB, single_coords, single_fn, single_spot_struct, dist_tol);
            if ~isempty(matchedName)
                RB = single_spots_to_scalar(single_spot_struct.(matchedName).resp);
            end
        end
    end

    % compute nli if possible
    denom = RA + RB;
    if isnan(Rp) || isnan(RA) || isnan(RB) || denom == 0
        nli_vals(i) = NaN;
    else
        nli_vals(i) = (Rp - denom) / denom;
    end
end

% Diagnostics
fprintf('paired entries: %d; centers with NaN rows: %d; distances NaN: %d\n', ...
    m, sum(any(isnan(centers),2)), sum(isnan(distances)));

% Keep only valid centers & distances
valid = ~any(isnan(centers),2) & ~isnan(distances);
centers = centers(valid,:);
distances = distances(valid);
nli_vals = nli_vals(valid);

if isempty(distances)
    key.distance_vals = [];
    key.paired_spots_nli_maps = {};
    key.paired_spots_maps_x = {};
    key.paired_spots_maps_y = {};
    return
end

% After computing centers and single_coords (right after parsing):
centers = round(centers);            % Nx2 integer centers

% Round distances to integer microns (choose round/floor/ceil as appropriate)
distances = round(distances);        % Nx1 integer distances

% compute distance bins
distance_vals = unique(distances, 'sorted');    % integer distances

% grid extents (integers)
pad = 1;
max_diam = max(distance_vals);
max_r = max_diam/2;
minx = min(centers(:,1)) - ceil(max_r) - pad;
maxx = max(centers(:,1)) + ceil(max_r) + pad;
miny = min(centers(:,2)) - ceil(max_r) - pad;
maxy = max(centers(:,2)) + ceil(max_r) + pad;
xv = (minx:maxx); yv = (miny:maxy);
[XG, YG] = meshgrid(xv, yv);  % integer grid

maps = cell(numel(distance_vals),1);
maps_x = repmat({xv}, numel(distance_vals),1);
maps_y = repmat({yv}, numel(distance_vals),1);

for k = 1:numel(distance_vals)
    d = distance_vals(k);
    idx = distances == d;
    if ~any(idx)
        maps{k} = nan(size(XG));
        continue
    end
    centers_k = centers(idx, :);
    nli_k = nli_vals(idx);
    accum = zeros(size(XG));
    count = zeros(size(XG));
    r = max(d/2, 0.5);    % you can keep 0.5 fallback
    r2 = r^2;

    for j = 1:size(centers_k,1)
        v = nli_k(j);
        if isnan(v), continue; end
        x0 = centers_k(j,1);
        y0 = centers_k(j,2);
        mask = (XG - x0).^2 + (YG - y0).^2 <= r2;
        accum(mask) = accum(mask) + double(v);
        count(mask) = count(mask) + 1;
    end
    map = nan(size(accum));
    validpix = count > 0;
    map(validpix) = accum(validpix) ./ count(validpix);
    maps{k} = map;

    fprintf('DEBUG: centers int range x=[%d %d] y=[%d %d], unique distances=%s\n', ...
        min(centers(:,1)), max(centers(:,1)), min(centers(:,2)), max(centers(:,2)), mat2str(unique(distances)'));

end

key.distance_vals = distance_vals(:);
key.paired_spots_nli_maps = maps;
key.paired_spots_maps_x = maps_x;
key.paired_spots_maps_y = maps_y;
end


%% Helper: parse single-spot fieldname into [x,y]
function xy = parse_single_fieldname(name)
% Parse single-spot name like '135__78' or '_135__78' -> [x y]
[nums, starts] = regexp(name, '(-?\d+\.?\d*)', 'match', 'start');
if numel(nums) < 2
    xy = [NaN NaN]; return
end

    function v = signed_num(idx)
        sidx = starts(idx);
        % count underscores immediately before token
        k = 0; p = sidx - 1;
        while p >= 1 && name(p) == '_'
            k = k + 1; p = p - 1;
        end
        n = str2double(nums{idx});
        % rule:
        % - if this is the first numeric token and k >= 1 -> negative
        % - otherwise if k >= 2 -> negative
        if (idx == 1 && k >= 1) || (idx ~= 1 && k >= 2)
            v = -n;
        else
            v = n;
        end
    end

x = signed_num(1);
y = signed_num(2);
xy = [x y];
end


function [coordA, coordB] = parse_pair_fieldname(fname)
% Parse pair names like 'x_30__156__30__130' -> coordA=[-30 -156], coordB=[-30 -130]
[nums, starts] = regexp(fname, '(-?\d+\.?\d*)', 'match', 'start');
if numel(nums) < 4
    coordA = [NaN NaN]; coordB = [NaN NaN]; return
end

    function v = signed_num(tokenIdx)
        sidx = starts(tokenIdx);
        k = 0; p = sidx - 1;
        while p >= 1 && fname(p) == '_'
            k = k + 1; p = p - 1;
        end
        n = str2double(nums{tokenIdx});
        % rule:
        % - for the first numeric token (xA): single leading '_' => negative
        % - for other tokens: two-or-more '_' => negative
        if (tokenIdx == 1 && k >= 1) || (tokenIdx ~= 1 && k >= 2)
            v = -n;
        else
            v = n;
        end
    end

xA = signed_num(1);
yA = signed_num(2);
xB = signed_num(3);
yB = signed_num(4);
coordA = [xA yA];
coordB = [xB yB];
end


%% Helper: reduce any resp (scalar/array) to scalar ignoring NaNs
function val = single_spots_to_scalar(x)
if isempty(x)
    val = NaN;
    return
end
if isscalar(x)
    val = double(x);
else
    val = double(mean(x(:),'omitnan'));
end
end

%% Helper: find nearest single-spot response within tol
%% find_single_resp_near (small tweak: return raw resp if present)
function val = find_single_resp_near(coord, single_coords, single_fn, single_spot_struct, tol)
val = NaN;
if any(isnan(coord)), return; end
d2 = sum((single_coords - coord).^2, 2);
[md2, idx] = min(d2);
if sqrt(md2) <= tol
    fld = single_fn{idx};
    if isfield(single_spot_struct.(fld), 'resp')
        val = single_spot_struct.(fld).resp; % return raw; caller will reduce to scalar
    else
        val = NaN;
    end
end
end

function fname = build_single_fieldname(coords, varargin)
% BUILD_SINGLE_FIELDNAME Build a field name from numeric coords.
%   fname = BUILD_SINGLE_FIELDNAME(coords)
%       coords : vector of numeric values [v1, v2, ...] (integers recommended)
%       fname  : string/char like 'x135__78_135__26' or 'x_30__52'
%
% Optional name/value pairs:
%   'Prefix'   : leading letter (default 'x')
%   'AsChar'   : return char (true) or string (false). Default true.
%
% Examples:
%   build_single_fieldname([135, -78])        -> 'x135__78'
%   build_single_fieldname([-30, -156])      -> 'x_30__156'
%   build_single_fieldname([135, -78, 135, -26]) -> 'x135__78_135__26'

% Parse inputs
p = inputParser;
addRequired(p, 'coords', @(v) isnumeric(v) && isvector(v));
addParameter(p, 'Prefix', 'x', @(s) ischar(s) || isstring(s));
addParameter(p, 'AsChar', true, @(b) islogical(b) || ismember(b,[0 1]));
parse(p, coords, varargin{:});
coords = double(p.Results.coords(:).'); % row
prefix = char(p.Results.Prefix);
asChar = p.Results.AsChar;

if isempty(coords)
    fname = prefix;
    if asChar, fname = char(fname); end
    return
end

parts = cell(1, numel(coords));
for k = 1:numel(coords)
    v = coords(k);
    av = abs(round(v));    % round to integer; change if you want other handling
    if k == 1
        % First token: negative -> single underscore prefix; positive -> no underscore
        if v < 0
            parts{k} = sprintf('_%d', av);
        else
            parts{k} = sprintf('%d', av);
        end
    else
        % Subsequent tokens: positive -> single underscore, negative -> double underscore
        if v < 0
            parts{k} = sprintf('__%d', av);
        else
            parts{k} = sprintf('_%d', av);
        end
    end
end

fname = [prefix, strjoin(parts, '')];

if asChar
    fname = char(fname);
else
    fname = string(fname);
end
end

function [idx, dist, matchedName, resp] = find_nearest_spot_progressive(targetCoord, single_coords, single_fn, single_spot_struct, tol)
% FIND_NEAREST_SPOT_PROGRESSIVE Progressive radial search for nearest spot.
%   [idx, dist, matchedName, resp] = FIND_NEAREST_SPOT_PROGRESSIVE(targetCoord, single_coords, single_fn, single_spot_struct, tol)
%     targetCoord           1x2 numeric [x y] (can be fractional; will be rounded)
%     single_coords         NSx2 numeric coordinates (should be integer-rounded already)
%     single_fn             NSx1 cell array of fieldnames
%     single_spot_struct    struct mapping fieldnames -> spot struct (with .resp)
%     tol                   scalar tolerance in same units (default 5)
%
%   Returns:
%     idx         index into single_coords / single_fn (empty if not found)
%     dist        Euclidean distance to nearest found spot (Inf if not found)
%     matchedName matched fieldname ('' if not found)
%     resp        scalar response from matched spot (NaN if not found)

if nargin < 5 || isempty(tol), tol = 5; end
% Normalize inputs
if isstring(targetCoord), targetCoord = double(targetCoord); end
target = round(double(targetCoord(:)).');         % 1x2 integer
single_coords = round(double(single_coords));     % NSx2 integers

idx = [];
dist = Inf;
matchedName = '';
resp = NaN;

if any(isnan(target)) || isempty(single_coords)
    return
end

% compute distances (not squared) from every single spot to target
d_all = pdist2(single_coords, target);    % NSx1 Euclidean distances
[bestDist, bestIdx] = min(d_all);

% If nearest is already within tol, return immediately
if bestDist <= tol
    idx = bestIdx;
    dist = bestDist;
    matchedName = single_fn{idx};
    resp = safe_extract_resp(single_spot_struct, matchedName);
    return
end

% Progressive integer-radius expansion
radii = unique([0.5, 1:ceil(tol)]);
for r = radii
    % find candidates within radius r (distances, not squared)
    candIdx = find(d_all <= r);
    if ~isempty(candIdx)
        [mdist, k] = min(d_all(candIdx));
        idx = candIdx(k);
        dist = mdist;
        matchedName = single_fn{idx};
        resp = safe_extract_resp(single_spot_struct, matchedName);
        return
    end
end

% nothing found within tol -> leave idx empty, resp NaN
end

% Helper to safely extract scalar response from spot struct
function r = safe_extract_resp(S, fname)
r = NaN;
try
    if isfield(S, fname)
        s = S.(fname);
        if isfield(s, 'resp')
            % If resp is vector, reduce to scalar similarly to your pipeline
            v = s.resp;
            if isnumeric(v)
                if isscalar(v), r = double(v);
                else r = double(mean(v(:))); end
            end
        end
    end
catch
    r = NaN;
end
end


