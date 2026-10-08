function [outPath, S] = fastExportResultsToH5(data_group, resultTableName, hierarchy, outPath)
%FASTEXPORTRESULTSTOH5 Fast replacement for the H5_Exporter export engine.
%
%   fastExportResultsToH5(data_group, 'DatasetSMSCA', ...
%       {'cell_type','quadrant','cell_name'}, out.h5)
%
%   data_group      DataJoint relation (e.g. DataGrouper_V2's queryResult)
%                   or a struct array of keys restricting the result table
%   resultTableName name of a table in sln_results (e.g. 'DatasetSMSCA')
%   hierarchy       cellstr of fields that define the HDF5 group hierarchy,
%                   e.g. {'cell_type','quadrant','cell_name'} produces
%                   /cell_type__ONAlpha/quadrant__DT/cell_name__081222Ac12
%   outPath         output .h5 file (created fresh each run)
%
%   Returns the output path and the flat struct array of everything written.
%
%   Produces the same per-entry fields as H5_Exporter (result-table fields
%   plus cell_name, cell_type, cell_class, quadrant, side, retina_id,
%   genotype_string, cell_event_*, animal ids, x, y, ...), plus
%   ip_injection_substances (e.g. STZ vs vehicle). Rows whose hierarchy
%   path collides get _1.._n suffixes (H5_Exporter parity).
%
%   Why it is fast: H5_Exporter built one giant server-side join in which
%   GenotypeString (an aggregation over the whole animal database) and
%   AssignType.current (a window over all cells) were recomputed for every
%   branch of the export recursion, then wrote each field with deprecated
%   hdf5write in append mode. Here every table is fetched once, restricted
%   to just the exported keys, joined in MATLAB, and written with the
%   low-level H5 API. Failed writes are real errors, never silent, and
%   entries dropped for missing metadata are reported.

t0 = tic;
assert(iscellstr(hierarchy) && ~isempty(hierarchy), 'hierarchy must be a cellstr'); %#ok<ISCLSTR>
resultTable = feval(sprintf('sln_results.%s', resultTableName));

% ---- 1) result rows, restricted once ----
if isstruct(data_group)
    keys = fetch(resultTable & data_group);
else
    keys = fetch(resultTable & proj(data_group));
end
if isempty(keys)
    error('fastExportResultsToH5:noResults', 'No %s rows match the data group', resultTableName);
end
R = fetch(resultTable & keys, '*');
tResults = toc(t0);

% ---- 2) metadata, each table fetched once with a simple key restriction ----
cellKeys = arrayfun(@(s) struct('file_name', s.file_name, 'source_id', s.source_id), R);
EC = fetch(sln_symphony.ExperimentCell & cellKeys, '*');
ecMap = keyMap(EC, @(s) sprintf('%s|%d', s.file_name, s.source_id));

haveRet = ~cellfun(@isempty, {EC.retina_id});
retKeys = arrayfun(@(s) struct('file_name', s.file_name, 'source_id', s.retina_id), EC(haveRet));
if isempty(retKeys)
    ER = struct([]);
else
    ER = fetch(sln_symphony.ExperimentRetina & retKeys, '*');
end
erMap = keyMap(ER, @(s) sprintf('%s|%d', s.file_name, s.source_id));

C = fetch(sln_cell.Cell & cellKeys, '*');
cMap = keyMap(C, @(s) sprintf('%s|%d', s.file_name, s.source_id));

unids = arrayfun(@(s) struct('cell_unid', s.cell_unid), C);
TY = fetch(sln_cell.AssignType * sln_cell.CellEvent & unids, '*');
tyMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
for i = 1:numel(TY)   % keep the latest event per cell (AssignType.current)
    u = TY(i).cell_unid;
    if ~isKey(tyMap, u) || isNewer(TY(i), tyMap(u))
        tyMap(u) = TY(i);
    end
end

animKeys = arrayfun(@(a) struct('animal_id', a), unique([C.animal_id]));
A = fetch(sln_animal.Animal & animKeys, '*');
aMap = keyMap(A, @(s) sprintf('%d', s.animal_id));
G = fetch(sln_animal.GenotypeString & animKeys, '*');
gMap = keyMap(G, @(s) sprintf('%d', s.animal_id));
I = fetch(sln_animal.AnimalEvent * sln_animal.IPInjection * sln_animal.InjectionSubstance ...
    & animKeys, 'animal_id', 'substance_name');
injMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
for i = 1:numel(A)
    names = unique({I([I.animal_id] == A(i).animal_id).substance_name});
    if isempty(names)
        injMap(sprintf('%d', A(i).animal_id)) = 'none recorded';
    else
        injMap(sprintf('%d', A(i).animal_id)) = strjoin(names, '; ');
    end
end

% ---- 3) stitch one flat struct per result row ----
S = [];
dropped = {};
for i = 1:numel(R)
    s = R(i);
    ck = sprintf('%s|%d', s.file_name, s.source_id);
    if ~isKey(ecMap, ck) || ~isKey(cMap, ck)
        dropped{end+1} = sprintf('%s %s src%d (no ExperimentCell/Cell row)', ...
            s.file_name, s.dataset_name, s.source_id); %#ok<AGROW>
        continue
    end
    ec = ecMap(ck);
    c = cMap(ck);
    if ~isKey(tyMap, c.cell_unid)
        dropped{end+1} = sprintf('%s %s src%d (cell_unid %d has no type assignment)', ...
            s.file_name, s.dataset_name, s.source_id, c.cell_unid); %#ok<AGROW>
        continue
    end
    ty = tyMap(c.cell_unid);

    s.cell_number = ec.cell_number;
    s.online_type = ec.online_type;
    s.x = ec.x;
    s.y = ec.y;
    s.retina_id = ec.retina_id;
    s.cell_name = sprintf('%sc%d', s.file_name, ec.cell_number);
    s.cell_unid = c.cell_unid;
    s.animal_id = c.animal_id;
    s.event_id = ty.event_id;
    s.cell_type = ty.cell_type;
    s.cell_class = ty.cell_class;
    s.cell_event_user_name = ty.user_name;
    s.cell_event_entry_time = ty.entry_time;
    s.notes = ty.notes;

    side = '';
    rk = sprintf('%s|%d', s.file_name, nvl(ec.retina_id, -1));
    if isKey(erMap, rk)
        side = erMap(rk).side;
    end
    s.side = side;
    s.quadrant = quadrantFromXY(ec.x, ec.y, side);

    ak = sprintf('%d', c.animal_id);
    if isKey(aMap, ak)
        s.animal_source_id = aMap(ak).source_id;
    else
        s.animal_source_id = [];
    end
    if isKey(gMap, ak)
        s.genotype_string = gMap(ak).genotype_string;
    else
        s.genotype_string = '';
    end
    if isKey(injMap, ak)
        s.ip_injection_substances = injMap(ak);
    else
        s.ip_injection_substances = 'none recorded';
    end

    if isempty(S)
        S = s;
    else
        S(end+1) = s; %#ok<AGROW>
    end
end
if isempty(S)
    error('fastExportResultsToH5:allDropped', 'Every result row was missing metadata');
end
tMeta = toc(t0);

% ---- 4) hierarchy paths (H5_Exporter naming parity), _n suffix on collisions ----
paths = cell(numel(S), 1);
for i = 1:numel(S)
    p = '';
    for h = 1:numel(hierarchy)
        v = S(i).(hierarchy{h});
        if isnumeric(v), v = num2str(v); end
        if isempty(v), v = 'null'; end
        p = [p '/' matlab.lang.makeValidName(sprintf('%s__%s', hierarchy{h}, v))]; %#ok<AGROW>
    end
    paths{i} = p;
end
[uPaths, ~, pidx] = unique(paths);
for u = 1:numel(uPaths)
    rows = find(pidx == u);
    if numel(rows) > 1
        for j = 1:numel(rows)
            paths{rows(j)} = sprintf('%s_%d', uPaths{u}, j);
        end
    end
end

% ---- 5) write, low-level API, file opened once ----
tW = tic;
fid = H5F.create(outPath, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
lcpl = H5P.create('H5P_LINK_CREATE');            % auto-create parent groups
H5P.set_create_intermediate_group(lcpl, 1);
strType = H5T.copy('H5T_C_S1');                  % variable-length UTF-8
H5T.set_size(strType, 'H5T_VARIABLE');
H5T.set_cset(strType, H5ML.get_constant_value('H5T_CSET_UTF8'));

nullFields = {};
try
    for i = 1:numel(S)
        fn = fieldnames(S(i));
        for k = 1:numel(fn)
            v = S(i).(fn{k});
            if isempty(v)
                if ~strcmp(fn{k}, 'notes')
                    nullFields{end+1} = sprintf('%s/%s', paths{i}, fn{k}); %#ok<AGROW>
                end
                continue
            end
            ds = [paths{i} '/' fn{k}];
            if ischar(v) || isstring(v)
                space = H5S.create_simple(1, 1, []);
                dset = H5D.create(fid, ds, strType, space, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
                H5D.write(dset, strType, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', {char(v)});
            elseif isnumeric(v) || islogical(v)
                v = double(v);
                if isvector(v) || isscalar(v)
                    space = H5S.create_simple(1, numel(v), []);
                    data = v(:);
                else
                    space = H5S.create_simple(ndims(v), fliplr(size(v)), []);
                    data = v;
                end
                dset = H5D.create(fid, ds, 'H5T_NATIVE_DOUBLE', space, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
                H5D.write(dset, 'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);
            else
                warning('fastExportResultsToH5:unhandledType', 'Skipped %s (class %s)', ds, class(v));
                continue
            end
            H5D.close(dset);
            H5S.close(space);
        end
    end
catch ME
    H5F.close(fid);
    rethrow(ME);
end
H5T.close(strType);
H5P.close(lcpl);
H5F.close(fid);

h5writeatt(outPath, '/', 'result_table', string(resultTableName));
h5writeatt(outPath, '/', 'hierarchy', strjoin(hierarchy, '/'));
h5writeatt(outPath, '/', 'exported', string(datetime('now')));
h5writeatt(outPath, '/', 'n_results', numel(S));
h5writeatt(outPath, '/', 'exporter', 'fastExportResultsToH5.m');

% ---- 6) report ----
fprintf('fastExportResultsToH5: %d %s results (%d unique paths) -> %s\n', ...
    numel(S), resultTableName, numel(uPaths), outPath);
if ~isempty(dropped)
    fprintf('  ! DROPPED %d result rows missing metadata:\n', numel(dropped));
    fprintf('    %s\n', dropped{:});
end
if ~isempty(nullFields)
    fprintf('  NULL fields skipped (%d):\n', numel(nullFields));
    fprintf('    %s\n', nullFields{:});
end
fprintf('  results %.2f s, metadata %.2f s, write %.2f s, total %.2f s\n', ...
    tResults, tMeta - tResults, toc(tW), toc(t0));
end

% ---------------- helpers ----------------

function m = keyMap(S, keyFcn)
m = containers.Map('KeyType', 'char', 'ValueType', 'any');
for i = 1:numel(S)
    m(keyFcn(S(i))) = S(i);
end
end

function tf = isNewer(a, b)
% mirror AssignType.current: latest entry_time, event_id as tiebreak
ta = datetime(a.entry_time);
tb = datetime(b.entry_time);
tf = ta > tb || (ta == tb && a.event_id > b.event_id);
end

function v = nvl(v, fallback)
if isempty(v)
    v = fallback;
end
end

function q = quadrantFromXY(x, y, side)
% mirror of sln_cell.RetinaQuadrant:
% IF((x=0 AND y=0) OR side LIKE "Unknown%", null,
%    IF((side="Left" AND x<0) OR (side="Right" AND x>0),
%       IF(y<0,"VT","DT"), IF(y<0,"VN","DN")))
if isempty(x) || isempty(y) || isempty(side) || ...
        (x == 0 && y == 0) || startsWith(side, 'Unknown')
    q = '';
elseif (strcmp(side, 'Left') && x < 0) || (strcmp(side, 'Right') && x > 0)
    if y < 0, q = 'VT'; else, q = 'DT'; end
else
    if y < 0, q = 'VN'; else, q = 'DN'; end
end
end
