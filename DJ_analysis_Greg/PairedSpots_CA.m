function R = PairedSpots_CA(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('PairedSpots_CA',N_datasets);
