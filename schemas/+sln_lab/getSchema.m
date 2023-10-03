function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_lab', 'sln_lab');
end
obj = schemaObject;
end
