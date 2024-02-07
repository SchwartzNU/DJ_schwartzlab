function [stratDict, stratLabels] = extract_strat_data_by_cell_type(base_folder, writeFiles)
if nargin < 1 || isempty(base_folder)
    base_folder = '~/OneDrive - Northwestern University/dAC_images/done/';
end
if nargin < 2
    writeFiles = false;
end


allCells_query = sln_cell.Cell * sln_cell.CellName * sln_cell.AssignType.current;
D = dir(base_folder);
stratDict = dictionary;
stratLabels = dictionary;
stratDict('empty') = {1};
stratLabels('empty') = {' '};

for i=1:length(D)
    cellName = D(i).name;
    thisCell = allCells_query & sprintf('cell_name="%s"',cellName);
    if thisCell.exists
        cellType = fetch1(thisCell,'cell_type')
        load([base_folder cellName filesep 'arborData.mat'],'appdata');
        stratX = appdata.strat_x';
        stratY = appdata.strat_y_norm';
        if ~isKey(stratDict,cellType)
            stratDict(cellType) = {[stratX, stratY]};
            stratLabels(cellType) = {[cellType '_' cellName '_x', ',', cellType '_' cellName '_y']};
        else
            stratDict(cellType) = {[stratDict{cellType}, stratX, stratY]};
            stratLabels{cellType} = [stratLabels{cellType}, ...
                ',', cellType '_' cellName '_x', ',', cellType '_' cellName '_y'];
        end            
    end
end

stratDict('empty') = [];
stratLabels('empty') = [];

if writeFiles
    k = keys(stratLabels);
    for i=1:length(k)
        cellType = k{i};
        f = fopen([cellType '.txt'], 'w');
        fwrite(f, stratLabels{cellType});
        fclose(f);
        writematrix(stratDict{cellType}, [cellType '.txt'], 'WriteMode', 'append');
    end
end