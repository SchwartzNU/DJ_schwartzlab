function passed = MB1000(entry)
passed = 0;
params = entry.protocol_params;
if isfield(params,'barSpeed')
    if params.barSpeed == 1000
        passed = 1;
    end
end