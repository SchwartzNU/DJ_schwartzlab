function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_cell', 'sln_cell');
end
obj = schemaObject;
end
