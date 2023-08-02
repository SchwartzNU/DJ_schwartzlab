function T = plot_result_values_by_celltype(data_group, result_table_name, result_field, each_epoch)
if nargin<4
    each_epoch = false;
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
        for n=1:N_items 
            val_means(n) = mean(vals{n});
        end
        T.(result_field)(i) = {val_means};
    end
end