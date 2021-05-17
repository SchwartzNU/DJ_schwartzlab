function positionStruct = extract_cellPositionsForQuery(q, fname)
positionStruct = struct;
f = fetch(q, 'position_x', 'position_y', 'side');

N_cells = length(f);
for i=1:N_cells
    curData = f(i);
    positionStruct(i).cell_id = curData.cell_id;
    positionStruct(i).whichEye = curData.side;
    positionStruct(i).posY = curData.position_y;
    %flip x coordinate for left eye
    if strcmp(curData.side, 'Left')
        positionStruct(i).posX = -curData.position_x;
    else
        positionStruct(i).posX = curData.position_x;
    end
end

s.posX = [positionStruct(:).posX]';
s.posY = [positionStruct(:).posY]';
s.whichEye = double(strcmp({positionStruct(:).whichEye}', 'Left'));
exportStructToHDF5(s, [fname '.h5'], '/')
save(fname, 'N_cells', 'positionStruct');