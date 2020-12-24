function [] = initAllTables()
S = sl.getSchema;
F = fieldnames(S.v);
for i=1:length(F)
    sl.(F{i})
end