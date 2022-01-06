function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_adil', 'sl');
end
obj = schemaObject;
end
