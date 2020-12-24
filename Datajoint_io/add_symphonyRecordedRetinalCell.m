function status = add_symphonyRecordedRetinalCell(cell_id)
cellData = loadAndSyncCellData(cell_id);
if isempty(cellData)
    status = sprintf('Failed to load %s', cell_id);
    return;
end

q.cell_id = cell_id;
thisCell = sl.SymphonyRecordedCell & q;
if thisCell.exists
    status = sprintf('%s is already in the database', cell_id);
    return;
end

%look for animal with matching date and rig in database
[date, rig] = cellID_to_dateAndRig(cell_id);
q = struct;
q.date = date;
q.rig_name = rig;
matchingAnimals = sl.Animal & (sl.AnimalEventReservedForSession & q);
L = matchingAnimals.count;
if L > 0
    animalList = matchingAnimals.fetch('animal_id','genotype_name','tag_id');
    whichEye = cellData.get('eye');
    fprintf('Eye identified at recording time as: %s\n', whichEye);
    
    for i=1:L
        fprintf('Entry %d:\n', i); 
        animalList(1)
    end
    str = input('Which entry and eye? [L or 1L = Entry 1 left eye; U for unknown eye; X to cancel] ','s')
    if strcmp(str,'X')
        disp('Cell insert aborted');
        return;
    else
        if length(str) == 1
           entry = 1;      
           whichEye = str(1);
        else
           entry = str2double(str(1));
           whichEye = str(2);
        end
        animalEyeData.animal_id = animalList(entry).animal_id;
        switch whichEye
            case 'L'
                animalEyeData.whichEye = 'Left';
            case 'R'
                animalEyeData.whichEye = 'Right';
            case 'U'
                animalEyeData.whichEye = 'Unknown1'; %deal with both unknown eyes?         
            otherwise
                disp('unreognized entry');
                disp('Cell insert aborted');
                return;
        end
    end      
else
    recordingBy = cellData.get('recordingBy');
    whichEye = cellData.get('eye');
    fprintf('Adding to database as recording by %s\n', recordingBy);
    fprintf('Eye identified at recording time as: %s\n', whichEye);
    
    h = AppDataHandle;
    app = AddDeceasedAnimal_dlg(cell_id, recordingBy, h);
    waitfor(app);
    if isempty(h.data.animal_id)
        status = 'Animal for this cell was not added';
        return;
    else
       animalEyeData = h.data; 
    end
end

%animal selected so now add the cell
C = dj.conn;
C.startTransaction;
try
    key.animal_id = animalEyeData.animal_id;
    key.cell_id = cell_id;
    insert(sl.MeasuredCell, key);
    id = max(fetchn(sl.MeasuredCell, 'cell_unid')); %last cell added
    if strcmp(animalEyeData.whichEye, 'Unknown')
        h.data.whichEye = 'Unknown1'; %keep track of both unknown eyes?
    end
    
    %MeasuredRetinalCell
    key.cell_unid = id;
    key.side = animalEyeData.whichEye;
    insert(sl.MeasuredRetinalCell, key);
    
    %load the cellData file into DJ through SymphonyRecordedCell
%     key_symCell.animal_id = key.animal_id;
%     key_symCell.cell_unid = key.cell_unid;
%     key_symCell.cell_id = cell_id;
%     insert(sl.SymphonyRecordedCell,key_symCell);
       
    C.commitTransaction;
    disp('Cell creation successful');
catch ME
    C.cancelTransaction;
    disp('Cell creation failed');
    rethrow(ME);
end

%Assign type
cellType_dataFile = cellData.get('type');
fprintf('Cell type in cellData file: %s\n', cellType_dataFile);
app = AssignCellType_dlg(key.cell_unid, key.animal_id, key.cell_id);

status = 'success';

