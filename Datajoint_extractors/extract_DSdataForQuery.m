function s = extract_DSdataForQuery(q, fname)
DS_struct = struct;
f = fetch(q, 'position_x', 'position_y', 'side','result');

N_cells = length(f);
z=1;
for i=1:N_cells
    i
    curData = f(i);
    cellType = fetch1(sl_mutable.CurrentCellType & sprintf('cell_id="%s"', curData.cell_id), 'cell_type');
    params = getExampleProtocolParametersForEpochInDataset(curData.cell_id, curData.dataset_name);
%     params.barSpeed
%     curData.side
%     curData.position_x
    %if i==23
   %     keyboard;
   % end
    if ~(curData.position_y == 0 && curData.position_x == 0) && ...
            (strcmp(curData.side, 'Left') || strcmp(curData.side, 'Right')) && ...
            ((contains(cellType, 'ON-OFF') && params.barSpeed == 1000) || ...
            (contains(cellType, 'ON DS transient') && params.barSpeed == 1000) || ...
            (contains(cellType, 'ON DS sustained') && params.barSpeed <= 1000))
        DS_struct(z).cell_id = curData.cell_id;
        DS_struct(z).whichEye = curData.side;
        DS_struct(z).posY = curData.position_y;
        DS_struct(z).cellType = cellType;
        DS_struct(z).barSpeed = params.barSpeed;
        %flip x coordinate for left eye and flip DSangle
        %temporal is to the left
        %nasal is angle 0
        %dorsal is angle 90
        if strcmp(curData.side, 'Left')
            DS_struct(z).posX = -curData.position_x;
            dsAng_rad = deg2rad(curData.result.spikeCountFull_DSang);
            [x,y] = pol2cart(dsAng_rad, 1);
            x = -x;
            [theta, ~] = cart2pol(x,y);
            DS_struct(z).DSang = rad2deg(theta);
        else
            DS_struct(z).posX = curData.position_x;
            DS_struct(z).DSang = curData.result.spikeCountFull_DSang;
        end
        DS_struct(z).DSI = curData.result.spikeCountFull_DSI;
        z=z+1
    end
end

s.posX = [DS_struct(:).posX]';
s.posY = [DS_struct(:).posY]';
s.whichEye = double(strcmp({DS_struct(:).whichEye}', 'Left')); %1 for left
s.DSI = [DS_struct(:).DSI]';
s.DSang = [DS_struct(:).DSang]';
s.barSpeed = [DS_struct(:).barSpeed]';
s.cellType = {DS_struct(:).cellType}';

% exportStructToHDF5(s, [fname '.h5'], '/')
% save(fname, 'N_cells', 'positionStruct');