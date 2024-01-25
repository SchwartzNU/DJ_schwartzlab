function [] = csvToH5(csv_fname, sorting_columns, vectorized_columns, ignore_columns, doPlot)
%sorting columns can include '*' which acts as a join to concatenate
%columns

if nargin < 5
    doPlot = false;
end

if nargin < 4
    ignore_columns = [];
end

if nargin < 3
    vectorized_columns = [];
end

T = readtable(csv_fname);
T = removevars(T, ignore_columns);

L = height(T);
for v=1:length(vectorized_columns)
    curVarName = vectorized_columns{v};
    curVals = T.(curVarName);
    for i=1:L
        temp = curVals{i};
        %temp = strrep(temp,'.',','); %TEMP HACK for raph's csvs with periods separating values
        temp = regexprep(temp,'\s+',' '); %remove linebreaks
        temp = ['[' temp ']']; %make it an array
        curVals{i} = eval(temp);
    end
    T.(curVarName) = curVals;
end

z = 1;
join_cols = [];
for v=1:length(sorting_columns) % are we going to allow more than 2?
    s = sorting_columns{v};
    if contains(s,'*')
        positions = strfind(s, '*');
        for p=1:length(positions)
            if p==1
                join_cols{1} = s(1:positions(1)-1);
                if length(positions)==p %last one
                    join_cols{p+1} = s(positions(p)+1:end);
                end
            else
                join_cols{p} = s(positions(p-1)+1:positions(p)-1);
                if length(positions)==p %last one
                    join_cols{p+1} = s(positions(p)+1:end);
                end
            end

        end
        new_name = strrep(s,'*','__');
        sorting_columns{v} = new_name;
        T = mergevars(T,join_cols,'NewVariableName',new_name);
    end
end

h5_name = strrep(csv_fname,'.csv','.h5');
getTableParts(T, h5_name, sorting_columns, '');

end

function T_vec = getTableParts(T, h5_name, sorting_columns, h5_group_str)
s = sorting_columns{1};

vals = T.(s);
vals_unique = sort(unique(vals));
for i=1:length(vals_unique)
    if iscell(vals_unique)

        curVal = vals_unique{i};
        T_part = T(strcmp(vals,curVal), :);
    else
        curVal = vals_unique(i);
        T_part = T(vals==curVal, :);
    end
    %recursive call
    if length(sorting_columns) == 1 %write it to h5
        T_part
        h5_group_str
        exportStructToHDF5(table2struct(T_part,"ToScalar",true), h5_name, ...
            [h5_group_str, '/', sprintf('%s__%s', s, genvarname(curVal))]);
    else
        sorting_columns(2:end)
        genvarname(curVal)
        getTableParts(T_part, h5_name, sorting_columns(2:end), ...
            [h5_group_str, '/', sprintf('%s__%s', s, genvarname(curVal))]);
    end
end
end
