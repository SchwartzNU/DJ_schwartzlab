function checkTopCameraCalibration(session_id)
C = dj.conn;
if strcmp(C.host, '127.0.0.1:3306')
    rootFolder = '/mnt/fsmresfiles/behavior';
elseif exist(getenv('SERVER_ROOT'), 'dir')
    rootFolder = [getenv('SERVER_ROOT') filesep 'BehaviorMaster'];
else
    disp('Aborting BehaviorSessionTrackingData import: Behavior folder not found');
end

thisSession = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('event_id=%d',session_id);
animal_id = fetch1(thisSession,'animal_id');
animal_folder = sprintf('%s%s%d',rootFolder, filesep, animal_id);
temp = dir([rootFolder filesep num2str(animal_id)]);
session_folders = {temp.name};
ind = find(startsWith(session_folders,[num2str(session_id) '_']));

if length(ind)==1
    folder_name = [animal_folder filesep session_folders{ind}];
else
    fprintf('Folder for session %d not found.\n', session_id);
    return;
end

calibration_file = [folder_name filesep 'calibration_top.csv'];

if ~exist(calibration_file, 'file')
    disp('Top camera calibration csv not found');
    return;
end

T = readtable(calibration_file);

camera_serial_number = '17391304';
if exist([folder_name filesep 'DLC_new'], 'dir')
    dlc_files = dir([folder_name filesep 'DLC_new']);
    dlc_filenames = {dlc_files.name};

    ind = find(startsWith(dlc_filenames, ['camera_' camera_serial_number]) ...
        & endsWith(dlc_filenames, '.mp4'));
else
    disp('DLC_new folder not found');
    return;
end

if isempty(ind)
    disp('Labeled video not found');
    return;
end

dlc_filenames{ind}

vidObj = VideoReader([folder_name filesep 'DLC_new' filesep dlc_filenames{ind}]);
frame = readFrame(vidObj);
figure(1);
imshow(frame);
hold('on');
plot(T.Center(1), T.Center(2), 'rx','MarkerSize',20,'LineWidth',4);
line([T.windowA_start(1), T.windowA_end(1)],[T.windowA_start(2), T.windowA_end(2)], 'Color', 'c', 'LineWidth', 4);
line([T.windowB_start(1), T.windowB_end(1)],[T.windowB_start(2), T.windowB_end(2)], 'Color', 'y', 'LineWidth', 4);
line([T.windowC_start(1), T.windowC_end(1)],[T.windowC_start(2), T.windowC_end(2)], 'Color', 'm', 'LineWidth', 4);
viscircles([T.Center(1), T.Center(2)], T.radius(1), 'Color','w','LineWidth',4);
hold('off');


end