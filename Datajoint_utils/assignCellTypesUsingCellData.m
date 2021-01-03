function [assigned_cells, unknown_cells] = assignCellTypesUsingCellData(fname)
if nargin<1 || ~exist(fname, 'file')
    [fname, fpath] = uigetfile('*.txt','Select plain text file with cell names.');
else
    fpath = '';
end

assigned_cells = [];
c = [];

allRGCs = sl.CellType & 'cell_class="RGC"';
name_full_list = allRGCs.fetchn('name_full');
name_short_list = allRGCs.fetchn('name_short');

if fname
    curTime = datestr(now);
    logName = sprintf('DJ_RGC_assignment_log_%s.txt', curTime);
    fprintf('Writing log in current directory as "%s"\n', logName);
    cell_ids = importdata([fpath, fname]);
    Ncells = length(cell_ids);
    fid = fopen(logName, 'w');
    fprintf(fid,'Attempting to assign %d cells\n', Ncells);
    
    matchFound = zeros(Ncells,1);
    
    for i=1:Ncells
        cell_id = cell_ids{i};        
        cellData = loadAndSyncCellData(cell_id);
        
        ind_full = find(strcmpi(cellData.cellType,name_full_list));
        ind_short = find(strcmpi(cellData.cellType,name_short_list));
        
        if isempty(ind_full) && isempty(ind_short)
            type_name = 'unknown';
            matchFound(i) = 0;
        elseif ~isempty(ind_full)
            type_name = name_full_list{ind_full};
            matchFound(i) = 1;
        elseif ~isempty(ind_short)
            type_name = name_full_list{ind_short};
            matchFound(i) = 1;
        end
        if matchFound(i)
            fprintf(fid,'%d: %s: Matched CellData type %s to %s\n', i, cell_id, cellData.cellType, type_name);
        else
            fprintf(fid,'%d: %s: No match found for CellData type %s \n', i, cell_id, cellData.cellType);
        end
        
        C = dj.conn;
        C.startTransaction;
        
        try
            thisCell = sl.SymphonyRecordedCell & sprintf('cell_id="%s"', cell_id);
            key = thisCell.fetch;
            key.user_name = C.user;
            key.cell_class = 'RGC';
            key.name_full = type_name;
            
            insert(sl.CellEventAssignType,key);
            
            key = rmfield(key,'user_name');
            key.cell_type = key.name_full;
            key = rmfield(key,'name_full');
            insert(sl.CurrentCellType, key, 'REPLACE');
            
            C.commitTransaction;            
            fprintf(fid,'%d: %s: Assignment successful\n', i, cell_id);
        catch ME
            C.cancelTransaction;
            fprintf(fid,'%d: %s: Assignment failed\n', i, cell_id);
            rethrow(ME);
        end
        
    end
    
    assigned_cells = cell_ids(matchFound==1);
    unknown_cells = cell_ids(matchFound==0);
end
