function [] = delete_experiment(exp_name)
c = sln_symphony.Experiment().descendants;

vc = cellfun(@(x) exist(x,'class'), c) == 8;
c(~vc) = [];
d = cellfun(@(x) length(feval(x).descendants), c);

[~,i] = sort(d);

for ci = i
      delQuick(feval(c{ci}) & 'file_name = "121622A"');
end
% for ci = i
%      delQuick(feval(c{ci}) & "`file_name` = '121622A'");
% end
%
% for ci = i
%     delQuick(feval(c{ci}) & sprintf("`file_name` = %s", exp_name));
% end