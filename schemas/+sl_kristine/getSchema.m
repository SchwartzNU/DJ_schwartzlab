function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_kristine', 'sl_kristine');
end
obj = schemaObject;
end
