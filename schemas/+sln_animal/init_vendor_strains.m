vendor_strains = struct(...
    'vendor_name', {},...
    'strain_name',{},...
    'catalog_number',{}...
);

%%% copy this and uncomment to add a new entry
% vendor_strains(end+1).vendor_name = 
% vendor_strains(end).strain_name = 
% vendor_strains(end).catalog_number = 

%source_info is an optional text field for notes

%% WT
vendor_strains(end+1).vendor_name = 'Jax';
vendor_strains(end).strain_name = 'WT';
vendor_strains(end).catalog_number = '000664';

%% CCK-ires-Cre
vendor_strains(end+1).vendor_name = 'Jax';
vendor_strains(end).strain_name = 'CCK-ires-Cre';
vendor_strains(end).catalog_number = '012706';

%% Vglut2-ires-Cre
vendor_strains(end+1).vendor_name = 'Jax';
vendor_strains(end).strain_name = 'Vglut2-ires-Cre';
vendor_strains(end).catalog_number = '028863';

%% Rosa26-CAGs-LSL-RIK knock-in
vendor_strains(end+1).vendor_name = 'Jax';
vendor_strains(end).strain_name = 'Rosa26-CAG-RIK';
vendor_strains(end).catalog_number = '029633';

%% Salsa6f
vendor_strains(end+1).vendor_name = 'Jax';
vendor_strains(end).strain_name = 'Salsa6f';
vendor_strains(end).catalog_number = '031968';

%% nNOS-CreER
vendor_strains(end+1).vendor_name = 'Jax';
vendor_strains(end).strain_name = 'nNOS-CreER';
vendor_strains(end).catalog_number = '014541';

%% Ai14
vendor_strains(end+1).vendor_name = 'Jax';
vendor_strains(end).strain_name = 'Ai14';
vendor_strains(end).catalog_number = '007914';
vendor_strains(end).source_info = 'floxed tdTomato reporter line';

