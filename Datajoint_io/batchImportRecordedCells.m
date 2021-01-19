function [inserted_cells, error_cells, already_in_cells] = batchImportRecordedCells(fname, auto_assign)
if nargin<1 || ~exist(fname, 'file')
    [fname, fpath] = uigetfile('*.txt','Select plain text file with cell names.');
else
    fpath = '';
end

if nargin<2
    auto_assign = true;
    load([getenv('DJ_root') 'CellTypeNameMatches.mat'], 'matchTable');
    rgcs = sl.CellType & 'cell_class="RGC"';
    typeNames = rgcs.fetchn('name_full');
end

inserted_cells = [];
error_cells = [];
already_in_cells = [];

if fname
    curTime = datestr(now);
    logName = sprintf('DJ_cell_import_log_%s.txt', curTime);
    fprintf('Writing log in current directory as "%s"\n', logName);
    cell_ids = importdata([fpath, fname]);
    Ncells = length(cell_ids);
    fid = fopen(logName, 'w');
    fprintf(fid,'Attempting to load %d cells\n', Ncells);
    
    inserted = zeros(Ncells,1);
    for i=1:Ncells
        error = false;
        cell_id = cell_ids{i};
        %handling cell_ids with multiple parts separated by ','
        cell_data_list = strsplit(cell_id, ',');
        Nparts = length(cell_data_list);
        for p=1:Nparts
            cell_data_list{p} = deblank(cell_data_list{p});
            cellData = loadAndSyncCellData(cell_data_list{p});
            
            if isempty(cellData)
                error = true;
                fprintf(fid, '%d: Failed to load cellData for %s\n', i, cell_data_list{p});
            end
            
            
            if ~error
                if p==1 %check only once
                    q.cell_id = cell_id;
                    thisCell = sl.MeasuredCell & q;
                    if thisCell.exists
                        error = true;
                        fprintf(fid,'%d: %s is already in the database\n', i, cell_id);
                    end
                    inserted(i) = 2;
                end
            end
            
            if ~error
                if p==1 %only insert cell once
                    whichEye = cellData.get('eye');
                    recordingBy = cellData.get('recordingBy');
                    
                    if isnan(recordingBy)
                        recordingBy = 'Unknown';
                    end
                    
                    %look for animal with matching date and rig in database
                    [date, rig] = cellID_to_dateAndRig(cell_id);
                    q = struct;
                    q.date = date;
                    q.rig_name = rig;
                    matchingAnimals = sl.Animal & (sl.AnimalEventReservedForSession & q);
                    L = matchingAnimals.count;
                    if L == 0 %add entry
                        fprintf(fid,'%d: No matching animal found for %s. Trying to add animal to database.\n', i, cell_id);
                        
                        %make insert key with default values
                        key = struct;
                        key.genotype_name = 'WT';
                        key.is_tagged = 'F';
                        %no DOB added so null
                        if isempty(whichEye) || all(isnan(whichEye))
                            eyeUnknown = true;
                        else
                            eyeUnknown = false;
                        end
                        
                        key.sex = 'Unknown';
                        key.source = 'unknown';
                        
                        %make rig reservation entry
                        key_reserved.user_name = recordingBy;
                        key_reserved.rig_name = rig;
                        key_reserved.date = date;
                        
                        %make AnimalDeceased entry
                        key_deceased.user_name = recordingBy;
                        key_deceased.date = date;
                        key_deceased.cause = 'sacrificed for experiment';
                        
                        %eye keys
                        if eyeUnknown
                            eye1.side = 'Unknown1';
                            eye2.side = 'Unknown2';
                        else
                            eye1.side = 'Left';
                            eye2.side = 'Right';
                        end
                        
                        C = dj.conn;
                        C.startTransaction;
                        try
                            fprintf(fid,'Trying insert in sl.Animal\n');
                            insert(sl.Animal, key);
                            
                            id = max(fetchn(sl.Animal, 'animal_id')); %last animmal added
                            
                            eye1.animal_id = id;
                            eye2.animal_id = id;
                            
                            fprintf(fid,'Trying inserts in sl.Eye\n');
                            insert(sl.Eye, eye1);
                            insert(sl.Eye, eye2);
                            
                            fprintf(fid,'Trying insert in sl.AnimalEventReservedForSession\n');
                            key_reserved.animal_id = id;
                            add_animalEvent(key_reserved, 'ReservedForSession',C);
                            
                            fprintf(fid,'Trying insert in sl.AnimalEventDeceased\n');
                            key_deceased.animal_id = id;
                            add_animalEvent(key_deceased, 'Deceased',C);
                            
                            C.commitTransaction;
                            fprintf(fid,'Animal insert successful\n');
                            matchingAnimals = sl.Animal & (sl.AnimalEventReservedForSession & q);
                            animalData = matchingAnimals.fetch('animal_id','genotype_name','tag_id');
                        catch
                            C.cancelTransaction;
                            fprintf(fid,'Animal insert failed\n');
                            error = true;
                            
                        end
                    elseif L == 1 %found single matching animal, assume that eyes and events are added correctly
                        animalData = matchingAnimals.fetch('animal_id','genotype_name','tag_id');
                        fprintf(fid,'%d: Found single matching animal for %s\n', i, cell_id);
                    else %found multiple matching animals - so error
                        error = true;
                        fprintf(fid,'%d: Found more than 1 possible matching animal for %s in the database, so it will need to be entered manually.\n', i, cell_id);
                    end
                end
            end
            
            %animal in DB so now add the cell
            if ~error
                if p==1 %only insert cell once
                    C = dj.conn;
                    C.startTransaction;
                    disp('starting cell insert');
                    try
                        disp('preparing MeasuredCell key');
                        key = struct;
                        key.animal_id = animalData.animal_id;
                        key.cell_id = cell_id;
                        
                        insert(sl.MeasuredCell, key);
                        id = max(fetchn(sl.MeasuredCell, 'cell_unid')); %last cell added
                        if isempty(whichEye) || all(isnan(whichEye)) || strcmp(whichEye, 'Unknown')
                            whichEye = 'Unknown1'; %keep track of both unknown eyes?
                        elseif strcmp(whichEye, 'left')
                            whichEye = 'Left';
                        elseif strcmp(whichEye, 'right')
                            whichEye = 'Right';
                        end
                        
                        disp('preparing MeasuredRetinalCell key');
                        %MeasuredRetinalCell
                        key.cell_unid = id;
                        key.side = whichEye;
                        thisEye = sl.Eye & key;
                        if thisEye.exists
                            insert(sl.MeasuredRetinalCell, key);
                        else
                            %insert the eye first
                            %need this because of weird situations where Unknown eye is added
                            %before left or right eye. This can happen if first cells imported were in Symphony 1
                            %and later ones are in Symphony 2
                            key_eye = struct;
                            key_eye.animal_id = key.animal_id;
                            key_eye.side = whichEye;
                            insert(sl.Eye, key_eye);
                            insert(sl.MeasuredRetinalCell, key);
                        end
                        
                        C.commitTransaction;
                        fprintf(fid,'%d: Successfully inserted cell %s\n', i, cell_id);
                        
                        cellType_online = cellData.get('type');
                        cellType_cellData = cellData.cellType;
                        fprintf('Cell type online file: %s\n', cellType_online);
                        fprintf('Cell type in cellData file: %s\n', cellType_cellData);
                        %Assign type
                        if auto_assign
                            key_type = struct;
                            key_type.cell_unid = key.cell_unid;
                            key_type.cell_id = key.cell_id;
                            key_type.animal_id = key.animal_id;
                            key_type.user_name = C.user;
                            key_type.cell_class = 'RGC';
                            
                            matchInd = strmatch(cellType_cellData, typeNames);
                            if ~isempty(matchInd)
                                key_type.name_full = typeNames{matchInd};
                            else
                                matchInd = strmatch(cellType_cellData, matchTable.cellData_type);
                                if ~isempty(matchInd)
                                    key_type.name_full = matchTable.db_type{matchInd};
                                else
                                    key_type.name_full = 'unknown';
                                end
                            end
                            RGCtype = key_type.name_full;
                            C.startTransaction;
                            insert(sl.CellEventAssignType,key_type);
                            
                            key_type = rmfield(key_type,'user_name');
                            key_type.cell_type = key_type.name_full;
                            key_type = rmfield(key_type,'name_full');
                            insert(sl_mutable.CurrentCellType, key_type, 'REPLACE');
                            
                            C.commitTransaction;
                            fprintf(fid,'Assigned cell %s cell as %s\n', cell_id, RGCtype);
                            fprintf('Assigned cell %s cell as %s\n', cell_id, RGCtype);
                        else
                            app = AssignCellType_dlg(key.cell_unid, key.animal_id, key.cell_id, cellType_cellData);
                            waitfor(app);
                        end
                    catch ME
                        C.cancelTransaction;
                        fprintf(fid,'%d: Error inserting cell %s\n', i, cell_id);
                        error = true;
                        rethrow(ME);
                    end
                end
            end
        end
        
        if ~error
            inserted(i) = 1;
        end
    end
    fprintf(fid,'Successfully loaded %d of %d cells. Returning inserted and error cell_ids.\n', sum(inserted==1), Ncells);
    fclose(fid);
    
    inserted_cells = cell_ids(inserted==1);
    error_cells = cell_ids(inserted==0);
    already_in_cells = cell_ids(inserted==2);
end



