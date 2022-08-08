function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_tissue', 'sln_tissue');
end
obj = schemaObject;
end
