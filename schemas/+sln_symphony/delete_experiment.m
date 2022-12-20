function [] = delete_experiment(exp_name)

%first delete cell type assignments
q = sln_symphony.ExperimentCell * ...
    sln_cell.Cell * ...
    sln_cell.CellEvent * ...
    sln_cell.AssignType & ...
    sprintf('file_name="%s"', exp_name);

unid = fetchn(q,'cell_unid');
unid_struct = struct('cell_unid', num2cell(unid));
del(sln_cell.CellEvent & unid_struct);

c = sln_symphony.Experiment().descendants;

vc = cellfun(@(x) exist(x,'class'), c) == 8;
c(~vc) = [];
d = cellfun(@(x) length(feval(x).descendants), c);

[~,i] = sort(d);

for ci = i
     temp = feval(c{ci}) ; 
     if any(strcmp(temp.header.names, 'file_name'))
         %if ~strcmp(c{ci},'sln_cell.Cell') %can't delete this one for some reason - foreign constraint fails
             fprintf('deleting %s\n', c{ci});
             delQuick(feval(c{ci}) & "`file_name` = '121622A'");
         %end
     end
end
% for ci = i
%       delQuick(feval(c{ci}) & 'file_name = "121622A"');
% end
%
% for ci = i
%     delQuick(feval(c{ci}) & sprintf("`file_name` = %s", exp_name));
% end