function visualizeSqueaksForSession(session_id)
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

squeak_query = sl_behavior.Squeaks & sprintf('event_id=%d',session_id);
if ~squeak_query.exists
    disp('Squeak table entry not found for this session');
    return;
end
squeak_data = fetch(squeak_query, '*');

gaze_query = sl_behavior.GazeData2D & sprintf('event_id=%d',session_id);
if ~gaze_query.exists
    disp('GazeData2D table entry not found for this session');
    return;
end
gaze_data = fetch(gaze_query, '*');

vidObj = VideoReader([folder_name filesep 'DLC_new' filesep dlc_filenames{ind}]);
frame = readFrame(vidObj);
figure(1);
imshow(frame);
hold('on');
hold('off');
keyboard;