function passed = testFilter(entry)
passed = 0;
params = entry.protocol_params;
if isfield(params,'motionPathMode')
    if strcmp(params.motionPathMode, 'random walk')
        passed = 1;
    end
end