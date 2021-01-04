function [filename, datasetname, variablenames] = parseExportSettings(exportState, entry)
%resultLevel = fieldnames(rmfield(exportState,'base_filename'));
input = entry.input;
results = entry.result;

filename_parts = {};
datasetname_parts = {};
var_parts = {};

if isempty(input) %single result
    filename = [exportState.base_filename, '.h5'];
    datasetname = '';
   
    switch exportState.ResultFields.saveas
       case 'variable names'
            var_parts = [var_parts,  '__r', 'varName'];
    end
            
    fields = fieldnames(results);
    Nfields=length(fields);
    variablenames = cell(Nfields,1);
    for f=1:Nfields
        variablenames{f} = '';
        varName = fields{f};
        for i=1:length(var_parts)
            if rem(i,2)==1
                variablenames{f} = [variablenames{f}, var_parts{i}];
            else
                variablenames{f} = [variablenames{f}, eval(var_parts{i})];
            end
        end
    end
else
    switch exportState.Animals.saveas
        case 'h5_filename'
            filename_parts = [filename_parts '__a', 'animal_id'];
        case 'dataset (Igor folder)'
            datasetname_parts = [datasetname_parts '__a', 'animal_id'];
        case 'variable names'
            var_parts = [var_parts '__a', 'animal_id'];
    end
    
    switch exportState.Eyes.saveas
        case 'h5_filename'
            filename_parts = [filename_parts, '__eye', 'side'];
        case 'dataset (Igor folder)'
            datasetname_parts = [datasetname_parts, '__eye', 'side'];
        case 'variable names'
            var_parts = [var_parts, '__eye', 'side'];
    end
    
    switch exportState.Cells.saveas
        case 'h5_filename'
            filename_parts = [filename_parts, '__c', 'cell_id'];
        case 'dataset (Igor folder)'
            datasetname_parts = [datasetname_parts,  '__c', 'cell_id'];
        case 'variable names'
            var_parts = [var_parts,  '__c', 'cell_id'];
    end
    
    switch exportState.Datasets.saveas
        case 'h5_filename'
            filename_parts = [filename_parts,  '__ds', 'dataset_name', '__ch', 'channel'];
        case 'dataset (Igor folder)'
            datasetname_parts = [datasetname_parts,  '__ds', 'dataset_name', '__ch', 'channel'];
        case 'variable names'
            var_parts = [var_parts,  '__ds', 'cell_id'];
    end
    
    switch exportState.Epochs.saveas
        case 'h5_filename'
            filename_parts = [filename_parts, '__e', 'epoch_number'];
        case 'dataset (Igor folder)'
            datasetname_parts = [datasetname_parts,  '__e', 'epoch_number'];
        case 'variable names'
            var_parts = [var_parts,  '__e', 'epoch_number'];
    end
    
    switch exportState.ResultFields.saveas
        case 'h5_filename'
            filename_parts = [filename_parts, '__r', 'varName'];
        case 'dataset (Igor folder)'
            datasetname_parts = [datasetname_parts,  '__r', 'varName'];
        case 'variable names'
            var_parts = [var_parts,  '__r', 'varName'];
    end
    
    retinalCell = sl.MeasuredRetinalCell & input;
    side = fetch1(retinalCell, 'side');
    animal_id = num2str(input.animal_id);
    cell_id = num2str(input.cell_id);
    if isfield(input, 'channel')
        channel = num2str(input.channel);
    end
    if isfield(input, 'dataset_name')
        dataset_name = input.dataset_name;
    end
    if isfield(input, 'epoch_number')
        epoch_number = num2str(input.epoch_number);
    end
    
    
    % filename_parts
    % datasetname_parts
    % var_parts
    
    filename = '';
    for i=1:length(filename_parts)
        if rem(i,2)==1
            filename = [filename, filename_parts{i}];
        else
            filename = [filename, eval(filename_parts{i})];
        end
    end
    filename = [exportState.base_filename, filename , '.h5'];
    
    datasetname = '';
    for i=1:length(datasetname_parts)
        if rem(i,2)==1
            datasetname = [datasetname, datasetname_parts{i}];
        else
            datasetname = [datasetname, eval(datasetname_parts{i})];
        end
    end
    
    fields = fieldnames(results);
    Nfields=length(fields);
    variablenames = cell(Nfields,1);
    for f=1:Nfields
        variablenames{f} = '';
        varName = fields{f};
        for i=1:length(var_parts)
            if rem(i,2)==1
                variablenames{f} = [variablenames{f}, var_parts{i}];
            else
                variablenames{f} = [variablenames{f}, eval(var_parts{i})];
            end
        end
    end
end