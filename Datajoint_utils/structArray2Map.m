function M = structArray2Map(s)

L = length(s);

if L > 0
    keys = fieldnames(s);
    N_keys = length(keys);

    for i=1:N_keys
        if isnumeric(s(1).(keys{i}))
            vals{i} = [s.(keys{i})];
        else
            vals{i} = {s.(keys{i})};
        end
    end

    M = containers.Map(keys, vals);

else
    M = containers.Map;
end
