function checkTopCameraTrackingData(session_id)
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

try
    nose_data = fetch(sl_behavior.NoseData2D & sprintf('event_id=%d',session_id),'*');
    gaze_data = fetch(sl_behavior.GazeData2D & sprintf('event_id=%d',session_id),'*');
    calibration = fetch(sl_behavior.TopCameraCalibration & sprintf('event_id=%d',session_id),'*');
catch
    disp('Did not find nose, gaze, and calibration data for this session');
    return
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

contact_threshold = 50; %pixels
vidObj = VideoReader([folder_name filesep 'DLC_new' filesep dlc_filenames{ind}]);
figure(1);
i=1;
while hasFrame(vidObj)
    frame = readFrame(vidObj);
    imshow(frame);
    hold('on');
    plot(calibration.center_x, calibration.center_y, 'rx','MarkerSize',20,'LineWidth',4);
    line([calibration.window_a_start(1), calibration.window_a_end(1)],[calibration.window_a_start(2), calibration.window_a_end(2)], 'Color', 'c', 'LineWidth', 4);
    line([calibration.window_b_start(1), calibration.window_b_end(1)],[calibration.window_b_start(2), calibration.window_b_end(2)], 'Color', 'y', 'LineWidth', 4);
    line([calibration.window_c_start(1), calibration.window_c_end(1)],[calibration.window_c_start(2), calibration.window_c_end(2)], 'Color', 'm', 'LineWidth', 4);
    viscircles([calibration.center_x, calibration.center_y], calibration.inner_wall_radius, 'Color','w','LineWidth',4);
    viscircles([calibration.center_x, calibration.center_y], 335, 'Color','w','LineWidth',4);

    [x, y] = pol2cart(gaze_data.bino_gaze_outer_wall(i), 335);
    x = x+calibration.center_x;
    y = y+calibration.center_y;
    plot(x,y, 'go','MarkerSize',10,'LineWidth',4,'MarkerFaceColor','g');
    if ismember(i,gaze_data.win_a_gaze_frames)
        text(50,80,'Gaze@A','FontSize',18','Color','c')
    elseif ismember(i,gaze_data.win_b_gaze_frames)
        text(50,80,'Gaze@B','FontSize',18','Color','y')
    elseif ismember(i,gaze_data.win_c_gaze_frames)
        text(50,80,'Gaze@C','FontSize',18','Color','m')
    end

    if nose_data.closest_window(i) == 1
        if nose_data.distance_from_window(i) < contact_threshold
            text(50,40,'Near A: window contact','FontSize',18','Color','c')
        else
            text(50,40,'Near A','FontSize',18','Color','c')
        end
    elseif nose_data.closest_window(i) == 2
        if nose_data.distance_from_window(i) < contact_threshold
            text(50,40,'Near B: window contact','FontSize',18','Color','y')
        else
            text(50,40,'Near B','FontSize',18','Color','y')
        end
    elseif nose_data.closest_window(i) == 3
        if nose_data.distance_from_window(i) < contact_threshold
            text(50,40,'Near C: window contact','FontSize',18','Color','m')
        else
            text(50,40,'Near C','FontSize',18','Color','m')
        end
    end


    hold('off');
    pause;
    i=i+1;
end

end