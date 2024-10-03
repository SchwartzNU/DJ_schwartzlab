function results_table = get_GLUT1_for_stacks(stack_query,vars,label_vars,fixed_vars)
%vars is a cell array of variable names on which to split 
%label vars is a cell array of variable names to list (for marking points)
%but not use to split
if nargin<4
    fixed_vars = {};
end
if nargin<3
    label_vars = {};
end
Nvars = length(vars);

all_cells_struct = fetch(sln_imquant.GLUT1Cell * stack_query,'*');
all_cells_table = struct2table(all_cells_struct,'AsArray',true);
for i=1:Nvars
    if ischar(all_cells_struct(1).(vars{i}))
        eval(sprintf('%s=unique({all_cells_struct.%s});',vars{i},vars{i}));
    else
        eval(sprintf('%s=unique([all_cells_struct.%s]);',vars{i},vars{i}));
    end
end
vars_arg = strjoin(vars,',');
eval(sprintf('conditions_table=combinations(%s);',vars_arg));
results_table = conditions_table;

for i=1:height(conditions_table)
    fprintf('Condition %d of %d\n', i, height(conditions_table))
    T = innerjoin(all_cells_table,conditions_table(i,:));    
    T = T(~isnan(T.glut1_top_surf),:);         
    glut1_vec = T.glut1_top_surf ./ T.membrane_top_surf;
    results_table.glut1_ratio_all{i} = glut1_vec;
    results_table.N(i) = length(glut1_vec);
    results_table.glut1_ratio_mean(i) = mean(glut1_vec);
    results_table.glut1_ratio_sd(i) = std(glut1_vec);
    results_table.glut1_ratio_sem(i) = std(glut1_vec)./(length(glut1_vec)-1);
    for v=1:length(label_vars)
        vals = categorical(T.(label_vars{v}));
        cats = categories(vals);
        results_table.([label_vars{v} '_categories']){i} = cats;
        numVec = zeros(height(T),1);
        for c=1:length(cats)
            numVec(vals==cats(c)) = c;
        end
        results_table.([label_vars{v} '_num']){i} = numVec;
    end
    if results_table.N(i)>0
        for v=1:length(fixed_vars)
            results_table.(fixed_vars{v})(i) = T.(fixed_vars{v})(1);
        end
    end
end
results_table = results_table(results_table.N>0,:);




