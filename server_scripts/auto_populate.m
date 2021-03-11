dj.conn;

oldFileNames = {};
oldFileTimes = [];

i = 0;

while true
    disp(datestr(now));
    i = i+1;
    
    cellDataFiles = dir('/mnt/fsmresfiles/CellDataMaster/*.mat');
    newFileNames = {cellDataFiles(:).name};
    newFileTimes = [cellDataFiles(:).datenum];

    newCellData = struct('cell_data',{});
    for j = 1:numel(newFileNames)
        k = find(strcmp(newFileNames(j), oldFileNames),1);
        if isempty(k) || newFileTimes(j) ~= oldFileTimes(k)
            newCellData(end+1) = struct('cell_data',{newFileNames{j}(1:end-4)});
        end
    end

    try
        del(sl_mutable.SpikeTrainMissing & newCellData);
        populateAll();
    catch ME
        messagetext = getReport(ME);
        disp(messagetext);
    end

    if mod(i,4320)==0 %it's been at least 12 hours
        oldFileTimes = [];
        oldFileNames = {};
    else
        oldFileTimes = newFileTimes;
        oldFileNames = newFileNames;
    end
    pause(10);
end