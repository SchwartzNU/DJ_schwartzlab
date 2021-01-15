function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_zach', 'sl_zach');
end
obj = schemaObject;
end
