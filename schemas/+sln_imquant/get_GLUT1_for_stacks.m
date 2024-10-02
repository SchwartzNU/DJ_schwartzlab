function conditions_table = get_GLUT1_for_stacks(stack_query,vars,label_vars)
%vars is a cell array of variable names on which to split 
%label vars is a cell array of variable names to list (for marking points)
%but not use to split
if nargin<3
    label_vars = {};
end
Nvars = length(vars);

all_cells_struct = fetch(sln_imquant.GLUT1Cell * stack_query,'*');
all_cells_table = struct2table(all_cells_struct,'AsArray',true);
for i=1:Nvars
    eval(sprintf('%s=unique({all_cells_struct.%s});',vars{i},vars{i}));    
end
vars_arg = strjoin(vars,',');
eval(sprintf('conditions_table=combinations(%s);',vars_arg));

for i=1:height(conditions_table)
    T = innerjoin(all_cells_table,conditions_table(i,:));
    T = T(~isnan(T.glut1_top_surf),:);    
    glut1_vec = T.glut1_top_surf ./ T.membrane_top_surf;
    conditions_table.glut1_ratio_all{i} = glut1_vec;
    conditions_table.N(i) = length(glut1_vec);
    conditions_table.glut1_ratio_mean(i) = mean(glut1_vec);
    conditions_table.glut1_ratio_sd(i) = std(glut1_vec);
    conditions_table.glut1_ratio_sem(i) = std(glut1_vec)./(length(glut1_vec)-1);
    for v=1:length(label_vars)
        vals = categorical(T.(label_vars{v}));
        cats = categories(vals);
        conditions_table.([label_vars{v} '_categories']){i} = cats;
        numVec = zeros(height(T),1);
        for c=1:length(cats)
            numVec(vals==cats(c)) = c;
        end
        conditions_table.([label_vars{v} '_num']){i} = numVec;
    end
end
conditions_table = conditions_table(conditions_table.N>0,:);




