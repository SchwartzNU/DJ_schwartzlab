function [inserted_cells, error_cells, already_in_cells] = batchImportRecordedCells(fname)
if nargin<1 || ~exist(fname, 'file')
    [fname, fpath] = uigetfile('*.txt','Select plain text file with cell names.');
else
    fpath = '';
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
        cellData = loadAndSyncCellData(cell_id);
        
        if isempty(cellData)
            error = true;
            fprintf(fid, '%d: Failed to load cellData for %s\n', i, cell_id);
        end
        
        if ~error
            q.cell_id = cell_id;
            thisCell = sl.MeasuredCell & q;            
            if thisCell.exists
                error = true;
                fprintf(fid,'%d: %s is already in the database\n', i, cell_id);
            end
            inserted(i) = 2;
            thisCell_struct = thisCell.fetch();
            
            %Assign type
            cellType_online = cellData.get('type');
            cellType_cellData = cellData.cellType;
            fprintf('Cell type online file: %s\n', cellType_online);
            fprintf('Cell type in cellData file: %s\n', cellType_cellData);                     
            app = AssignCellType_dlg(thisCell_struct.cell_unid, thisCell_struct.animal_id, thisCell_struct.cell_id);
            waitfor(app);
            
        end
        
        if ~error
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
                
                %add the animal
                %key
                %key_reserved
                %key_deceased
                
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
        
        %animal in DB so now add the cell
        if ~error
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
                insert(sl.MeasuredRetinalCell, key);
                
                C.commitTransaction;
                fprintf(fid,'%d: Successfully inserted cell %s\n', i, cell_id);
                
                %Assign type
                cellType_dataFile = cellData.get('type');
                fprintf('Cell type in cellData file: %s\n', cellType_dataFile);
                app = AssignCellType_dlg(key.cell_unid, key.animal_id, key.cell_id);
                waitfor(app);
            catch ME
                C.cancelTransaction;
                fprintf(fid,'%d: Error inserting cell %s\n', i, cell_id);
                error = true;
                rethrow(ME);
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



