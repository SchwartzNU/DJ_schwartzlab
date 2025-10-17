function prot_name = sqlProtName2ProtName(sql_prot_name)
temp = strrep(sql_prot_name, '_', ' ');
temp = capitalize(temp, {'a','an','or','in','the'});
prot_name = strrep(temp, ' ', '');
