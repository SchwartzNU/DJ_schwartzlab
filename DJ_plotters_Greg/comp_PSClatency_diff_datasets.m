function required_fields = comp_PSClatency_diff_datasets(R, ax)

if nargin < 1
    required_fields = {'latency_opto_ms'};
    return;
end

total_color_set = cool(height(R));
hold (ax, "on");
colororder("reef")
xtick_labels = {};
for n = 1:height(R)

    y = cell2mat(R.latency_opto_ms(n));
    x = zeros([1, numel(y)]);
    x = x+n;
    col = total_color_set(n, :);
    scatter(x, y,5, col, 'filled');
    name =  R.dataset_name(n);
    xtick_labels{end+1} =name{1};
end
set(ax,'XtickMode','manual');
myxti = linspace(1, height(R), height(R));
xticks(ax, myxti);
xticklabels(ax, xtick_labels);

end