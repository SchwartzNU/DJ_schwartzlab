function saveQuery(query, query_name, project_name, replace)
%SAVEQUERY Save a DataJoint query into sln_lab.Query.
%
%   sln_lab.saveQuery(query, 'my_query_name') stores the relation's SQL in
%   sln_lab.Query under the current database user (dj.conn().user, the same
%   attribution DataGrouper_V2 uses when saving a query).
%
%   sln_lab.saveQuery(query, name, project) also files it under an existing
%   sln_lab.Project.
%
%   sln_lab.saveQuery(query, name, project, true) replaces an existing
%   query with the same name/user (pass '' for project to skip it).
%
%   The saved query shows up in QueryBrowser and runs via
%   q.runAndFetch() / q.runAndFetchAnalysisResult(resultName) where
%   q = sln_lab.Query & 'query_name = "..."'.
%
%   Note: this stores only the database-side query. The .mat queryState
%   files DataGrouper_V2 writes (for reloading its search UI) are separate.

if nargin < 2 || isempty(query_name)
    error('sln_lab:saveQuery:noName', ...
        'Provide a name: sln_lab.saveQuery(query, name [, project, replace])');
end
if nargin < 3
    project_name = '';
end
if nargin < 4
    replace = false;
end
assert(isa(query, 'dj.internal.GeneralRelvar'), ...
    'query must be a DataJoint relation (got %s)', class(query));

q_str = query.sql;
assert(length(q_str) <= 60000, ...
    'query SQL is %d characters; sln_lab.Query holds at most 60000', length(q_str));

key.query_name = char(query_name);
key.user_name = dj.conn().user;

if exists(sln_lab.Query & key)
    if ~replace
        error('sln_lab:saveQuery:exists', ...
            'Query "%s" already exists for user %s. Pass true as the 4th argument to replace it.', ...
            key.query_name, key.user_name);
    end
    delQuick(sln_lab.Query & key);
end

key.sql_query = q_str;
if ~isempty(project_name) && ~strcmp(project_name, ' ')
    project_name = char(project_name);
    if ~exists(sln_lab.Project & struct('project_name', project_name))
        error('sln_lab:saveQuery:noProject', ...
            'No sln_lab.Project named "%s". Available: %s', project_name, ...
            strjoin(fetchn(sln_lab.Project, 'project_name')', ', '));
    end
    key.project_name = project_name;
end
insert(sln_lab.Query, key);

if isfield(key, 'project_name')
    fprintf('sln_lab.saveQuery: saved "%s" (user %s, project %s)\n', ...
        key.query_name, key.user_name, key.project_name);
else
    fprintf('sln_lab.saveQuery: saved "%s" (user %s)\n', key.query_name, key.user_name);
end
end
