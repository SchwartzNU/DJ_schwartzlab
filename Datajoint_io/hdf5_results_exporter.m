all_results = sln_results.DatasetSMSCA * ...    
    proj(sln_symphony.ExperimentRetina, 'source_id->retina_source_id') * ...
    sln_animal.Eye * proj(sln_animal.Animal, 'source_id->animal_source_id') * ...
    sln_animal.GenotypeString * ...
    sln_symphony.ExperimentCell * ...
    proj(sln_cell.CellEvent) * ...
    proj(sln_cell.RetinaQuadrant, 'quadrant') * ...
    proj(sln_cell.CellName, 'cell_name') * ...
    sln_cell.AssignType & proj(data_group);

fields_to_remove = {'source_id', ...
    'retina_source_id', ...
    'event_id', ...
    'cell_unid', ...
    'entry_time', ...
    'git_tag', ...
    'retina_id', ...
    'cell_number', ...
    'online_type', ...
    'x', ...
    'y' ...    
    };

property_list = setdiff(all_results.header.notBlobs, fields_to_remove);
