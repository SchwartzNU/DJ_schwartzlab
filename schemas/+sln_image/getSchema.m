function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_image', 'sln_image');
end
obj = schemaObject;
end
