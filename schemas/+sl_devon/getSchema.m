function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_devon', 'sl_devon');
end
obj = schemaObject;
end
