function t = mym2table(s)
    % mym results are returned as a scalar struct with Nx1 fields for each
    % element
    
    c = struct2cell(s);
    d = cellfun(@(x) ~isa(x,'cell'), c); %scalar numeric entities are returned as vectors
    c(d) = cellfun(@num2cell, c(d), 'uni', 0); %convert the vectors to cell arrays
    cc = horzcat(fieldnames(s),c)'; %convert the data into the input arguments for an N-by-1 struct
    t = struct2table(struct(cc{:})); %convert to table via struct
end