function sql_prot_name = protName2SqlProtName(prot_name)
upper_locs = find(isstrprop(prot_name,'upper'));
temp = prot_name;
for i=2:length(upper_locs)
    if i==2
        temp = insertBefore(prot_name, upper_locs(i), '_');
    else
        temp = insertBefore(temp, upper_locs(i)+i-2, '_');
    end
end
sql_prot_name = lower(temp);