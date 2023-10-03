function [] = read_excel_table_into_DJ(table_name)
lookup_table_folder = [getenv('DJ_ROOT') 'Lookup_table_spreadsheets' filesep];
xls_name = [strrep(table_name, '.', '__') '.xlsx'];
T = readtable([lookup_table_folder xls_name]);
S = table2struct(T);

if contains(table_name, 'FluorescentReagent')
    reagent_type = 'FluorescentReagent';
elseif contains(table_name, 'Antibody')
    reagent_type = 'Antibody';
end

for i=1:length(S)
%    i
    reagent_name = S(i).reagent_name;
    try        
        sln_tissue.add_reagent(S(i), reagent_type);
        fprintf('Inserted %s\n', reagent_name);
%        c = count(sln_tissue.FluorescentReagent)
%         if c~=i
%             keyboard;
%         end

    catch ME
        fprintf('Insertion of %s failed: %s\n', reagent_name, ME.message);
    end
end