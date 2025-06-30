function table2h5(conditions_table,fname)
S = table2struct(conditions_table);

for i=1:length(S)
    exportStructToHDF5(S(i),fname,sprintf('/condition_%d',i));    
end