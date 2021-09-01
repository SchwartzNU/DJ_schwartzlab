function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_animal', 'sln_animal');
end
obj = schemaObject;
end
