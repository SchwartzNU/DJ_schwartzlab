function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_results', 'sl_results');
end
obj = schemaObject;
end
