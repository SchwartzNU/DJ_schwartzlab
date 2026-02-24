function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_sql', 'sln_sql');
end
obj = schemaObject;
end
