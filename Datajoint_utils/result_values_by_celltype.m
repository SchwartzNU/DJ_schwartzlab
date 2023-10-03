function T = result_values_by_celltype(data_group, result_table_name, result_field, each_epoch, remove_outliers)
if nargin<4
    each_epoch = false;
end
if nargin<5
    remove_outliers = false;    
end

if remove_outliers
    std_thres = 3;
end

T = table;
q = eval(result_table_name) * proj(sln_cell.AssignType.current,'cell_type') & proj(data_group);
cell_types = unique(fetchn(q,'cell_type'));

N_types = length(cell_types);
T = table('Size',[N_types 2],'VariableTypes',{'string', 'cell'},'VariableNames',{'CellType', result_field});
for i=1:N_types
    cur_type = cell_types{i};
    q_cur_type = q & sprintf('cell_type="%s"', cur_type);
    T.CellType(i) = cur_type;
    vals = fetchn(q_cur_type, result_field);
    if ~iscell(vals) || each_epoch
        T.(result_field)(i) = {vals};
    else
        N_items = length(vals);
        val_means = zeros(N_items,1);
        if remove_outliers
            val_stds = zeros(N_items,1);
        end
        for n=1:N_items
            val_means(n) = mean(vals{n});
            if remove_outliers
                val_stds(n) = std(vals{n});
                outliers = abs(vals{n} - val_means(n)) > val_stds(n)*std_thres;
                temp = vals{n};
                temp = temp(~outliers);
                val_means(n) = mean(temp);
                N_outliers = sum(outliers);
                if N_outliers>1
                    fprintf('Dropping %d outliers for type %s\n', N_outliers, cur_type);
                end
            end
        end
        %val_means = 1E8*(val_means * 10)*1E-6/0.9;
        T.(result_field)(i) = {val_means};
    end
end

