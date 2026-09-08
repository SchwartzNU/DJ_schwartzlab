function [outPath, S] = exportSMSCAToH5(queryName, outPath)
%EXPORTSMSCATOH5 Export DatasetSMSCA results for a saved DataGrouper query.
%
%   exportSMSCAToH5('STZ_sham_alphas_SMS_CS') loads
%   <queryFolder>/<queryName>.mat (saved by DataGrouper_V2's "Save query"),
%   restricts sln_results.DatasetSMSCA by that query, and writes
%   <h5_folder>/<queryName>.h5 with the hierarchy
%       /cell_type__<Type>/quadrant__<Q>/cell_name__<name>
%   using fastExportResultsToH5 (single-pass fetch, low-level H5 writes,
%   loud reporting of dropped/NULL entries, per-cell
%   ip_injection_substances so STZ vs vehicle is recoverable).
%
%   [outPath, S] = exportSMSCAToH5(...) also returns the exported rows.

if nargin < 1 || isempty(queryName)
    queryName = 'STZ_sham_alphas_SMS_CS';
end
qFolder = strrep(getenv('queryFolder'), '~', getenv('HOME'));
if nargin < 2 || isempty(outPath)
    h5Folder = strrep(getenv('h5_folder'), '~', getenv('HOME'));
    outPath = fullfile(h5Folder, [queryName '.h5']);
end

L = load(fullfile(qFolder, [queryName '.mat']), 'queryState');
qr = parseQueryStructV3(L.queryState, L.queryState.searchTable);
if ischar(qr)
    error('exportSMSCAToH5:badQuery', 'Could not parse query %s', queryName);
end

% Materialize the query into plain keys immediately: relations restored
% from a saved queryState cause connection churn (each later fetch pays a
% fresh TLS reconnect) if they stay in play.
tq = tic;
keys = fetch(sln_results.DatasetSMSCA & proj(qr));
fprintf('exportSMSCAToH5: query "%s" -> %d DatasetSMSCA keys (%.2f s)\n', ...
    queryName, numel(keys), toc(tq));
clear qr L

[outPath, S] = fastExportResultsToH5(keys, 'DatasetSMSCA', ...
    {'cell_type', 'quadrant', 'cell_name'}, outPath);
h5writeatt(outPath, '/', 'query_name', string(queryName));

% condition summary (STZ vs vehicle) per animal
animalIDs = unique([S.animal_id]);
for a = animalIDs(:)'
    inCount = sum([S.animal_id] == a);
    idx = find([S.animal_id] == a, 1);
    fprintf('  animal %d: IP injections = %s (%d results)\n', ...
        a, S(idx).ip_injection_substances, inCount);
end
end
