function R = collectResults(cell_results)
N = length(cell_results);
fields = fieldnames(cell_results{1});
for i=1:length(fields)
    if isscalar(cell_results{1}.(fields{i}))
        R.(fields{i}) = zeros(N,1);
        for n=1:N
            R.(fields{i})(n) = cell_results{n}.(fields{i});
        end
    elseif ischar(cell_results{1}.(fields{i}))
        R.(fields{i}) = cell(N,1);
        for n=1:N
            R.(fields{i}){n} = cell_results{n}.(fields{i});
        end
    end
end
