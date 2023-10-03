function [] = add_cell_types_from_cellData(cellNames)
load('CellTypeNameMatches','matchTable');

C = dj.conn;
key.user_name = C.user;
db_types = fetchn(sln_cell.CellType,'cell_type');

for i=1:length(cellNames)
    if ~isempty(cellNames{i})
        [file_name,cell_str] = strtok(cellNames{i},'c');
        cell_num = str2double(cell_str(2:end));
        thisCell = sln_cell.Cell * sln_symphony.ExperimentCell ...
            & sprintf('file_name="%s"', file_name) ...
            & sprintf('cell_number=%d', cell_num);

        if thisCell.count ~= 1
            error('Looking for 1 matching cell for in database for %s but found %d', cellNames{i}, thisCell.count);
        end

        key.cell_unid = fetch1(thisCell,'cell_unid');

        cellData = loadAndSyncCellData(cellNames{i});
        cellData_type = cellData.cellType;
        ind = find(strcmp(cellData_type, db_types));
        if ~isempty(ind)
            fprintf('found type %s\n', db_types{ind})
            key.cell_type = db_types{ind};
            key.cell_class = fetch1(sln_cell.CellType & sprintf('cell_type="%s"', db_types{ind}), 'cell_class');
        else
            ind = find(strcmp(cellData_type, matchTable.cellData_type));
            if ~isempty(ind)
                fprintf('found type %s matching %s\n', matchTable.cellData_type{ind}, matchTable.db_type{ind});
                key.cell_type = matchTable.db_type{ind};
                key.cell_class = fetch1(sln_cell.CellType & sprintf('cell_type="%s"', matchTable.db_type{ind}), 'cell_class');
            else
                fprintf('CellData type %s marked as unclasified or unkown\n', cellData_type);
                if contains(cellData_type, 'RGC')
                    key.cell_type = 'unknown';
                    key.cell_class = 'RGC';
                elseif contains(cellData_type, 'amacrine')
                    key.cell_type = 'unknown';
                    key.cell_class = 'amacrine';
                else
                    key.cell_type = 'unclassified';
                    key.cell_type = 'other';
                end
            end
        end
        sln_cell.add_event(key,'AssignType');
    end
end