function required_fields = comp_PSClatency_diff_datasets(R, ax)

if nargin < 1
    required_fields = {'latency_opto_ms'};
    return;
end

total_color_set = cool(numel(R));
hold (ax, "on");
%colororder("reef")
xtick_labels = {};
for n = 1:numel(R)
    name =  R(n).dataset_name;
    %dealing with annoying underscore mark
    underscore_flag = sum(ismember(name, '_'));
    if (underscore_flag)
        new_name_ar = split(name, '_');
        name = '';
        for j = 1:numel(new_name_ar)
            name =  append(name, new_name_ar(j));
        end
    end
    if (iscell(name))
        name = name{1};
    end
    
    if (R(n).psc_total_dataset == 0)
        
        xtick_labels{end+1} =name;
        continue;
    end
    y = R(n).latency_opto_ms;
    x = zeros([1, numel(y)]);
    x = x+n;
    col = total_color_set(n, :);
    scatter(ax, x, y, 8, col, 'filled');
    %name =  R(n).dataset_name;
    xtick_labels{end+1} =name;
end
set(ax,'XtickMode','manual');
set(ax, 'YtickMode', 'auto');
myxti = linspace(1, numel(R), numel(R));
xticks(ax, myxti);
xticklabels(ax, xtick_labels);

ylabel(ax, 'PSC latency (ms)');
%ylabel(ax, 'data')

end