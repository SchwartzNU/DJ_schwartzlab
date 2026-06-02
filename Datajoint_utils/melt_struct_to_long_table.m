function T_table = melt_struct_to_long_table(struct_to_melt, var_names_to_rm)

new_struct = rmfield(struct_to_melt, var_names_to_rm);

var_names = fieldnames(new_struct);

T = struct();

for i = 1:length(new_struct)
    struct_var_length = zeros(length(var_names), 1);
    % the code is ugly but idgaf
    for name = 1 : length(var_names)
        struct_var_length(name) = size(new_struct(i).(var_names{name}),1);
    end
    wide_var = var_names(find(struct_var_length > 1));
    n_row_to_melt = max(struct_var_length);
    last_row = size(T, 2);
    for name = 1 : length(var_names)
        var = var_names{name};
        for j = 1 : n_row_to_melt
            if ismember(var, wide_var)
                T(last_row + j).(var) = new_struct(i).(var)(j);
            else
                T(last_row + j).(var) = new_struct(i).(var);
            end
        end
    end

    
    

end

T_table = struct2table(T(2:end))

end