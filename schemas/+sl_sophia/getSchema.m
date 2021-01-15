function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_sophia', 'sl_sophia');
end
obj = schemaObject;
end
