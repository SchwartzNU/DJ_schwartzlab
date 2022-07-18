function [] = createTable(R,resultLevel)
var_names_to_append = {'-> sln_lab.User','entry_time = CURRENT_TIMESTAMP','git_tag'};
var_desc_to_append = {...
    'user who entered this result', ...
    'time the result was entered', ...
    'git tag of current version of DJ_ROOT folder' ...
    };

var_names = R.Properties.VariableNames;
var_desc = [R.Properties.VariableDescriptions, var_desc_to_append];

N_vars = length(var_names);
var_types = cell(N_vars,1);

for i=1:N_vars
    %class(R.(var_names{i})(1))
    switch class(R.(var_names{i})(1))
        case 'string'
            var_types{i} = 'varchar(128)';
        case 'uint16'
            var_types{i} = 'int unsigned';
        case 'double'
            var_types{i} = 'float';
        case 'cell'
            var_types{i} = 'longblob';
        otherwise
            error('No case for type %s\n', class(R.(var_names{i})(1)));
    end
end

var_names = [var_names, var_names_to_append];
var_types = [var_types; {'key'; 'timestamp'; 'varchar(128)'}];

switch resultLevel
    case 'Experiment'
    case 'Animal'
    case 'Eye'
    case 'Cell'
    case 'Cell pair'
    case 'Dataset'
        primary_vars = {'file_name', 'dataset_name', 'source_id'};
        if ~all(ismember(primary_vars,var_names))
            error('Dataset results must contain file_name and dataset_name columns');
        end
        secondary_vars = setdiff(var_names, primary_vars);
    case 'Epoch'

end

N_header_rows = length(var_names) + 4;
table_header_str = cell(N_header_rows,1);
table_header_str{1} = '%{';
table_name = sprintf('%s%s',resultLevel,strrep(R.Properties.UserData,'_',''));
table_header_str{2} = ['# ' table_name];
z = 3;
for i=1:length(primary_vars)
    ind = find(strcmp(var_names,primary_vars{i}));
    table_header_str{z} = sprintf('%s : %s # %s', primary_vars{i}, var_types{ind}, var_desc{ind});
    z=z+1;
end
table_header_str{z} = '---';
z=z+1;
for i=1:length(secondary_vars)
    ind = find(strcmp(var_names,secondary_vars{i}));
    if strcmp(var_types{ind},'key')
        table_header_str{z} = sprintf('%s # %s', secondary_vars{i}, var_desc{ind});
    else
        table_header_str{z} = sprintf('%s : %s # %s', secondary_vars{i}, var_types{ind}, var_desc{ind});
    end
    z=z+1;
end
table_header_str{z} = '%}';

table_def_str{1} = sprintf('classdef %s < dj.Manual', table_name);
table_def_str{2} = 'end';

fname = fullfile(getenv('DJ_ROOT'),'schemas','+sln_results',sprintf('%s.m',table_name));
fid = fopen(fname,'w');
for i=1:length(table_header_str)
    fprintf(fid,'%s\n',table_header_str{i});
end
for i=1:length(table_def_str)
    fprintf(fid,'%s\n',table_def_str{i});
end
fclose(fid);
%initialize the table - can't do it within app apparently
rehash('path');
eval(sprintf('sln_results.%s',table_name));
