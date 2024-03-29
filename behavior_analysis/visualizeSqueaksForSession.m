function visualizeSqueaksForSession(session_id, which_calls)
if nargin<2
    which_calls = 'all';
end

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

tracking_query = sl_behavior.TrackingData2D & sprintf('event_id=%d',session_id);
if ~tracking_query.exists
    disp('TrackingData2D table entry not found for this session');
    return;
end
tracking_data = fetch(tracking_query, '*');
varNames = tracking_data.dlc_raw.top_parts;
M = tracking_data.dlc_raw.top;
Nvars = length(varNames);
DLC_raw_table_top = table('Size',[size(M,1), Nvars], ...
    'VariableNames', varNames, ...
    'VariableTypes', string(repmat('double',length(varNames), 1)));
DLC_raw_table_top{:,:} = M;

vidObj = VideoReader([folder_name filesep 'DLC_new' filesep dlc_filenames{ind}]);
frame = readFrame(vidObj);
figure(1);
imshow(frame);
hold('on');
ax = gca;

if strcmp(which_calls, 'all')
    N_call_types = 10;
    call_ids = 0:9;
elseif strcmp(which_calls, 'adult')
    N_call_types = 5;
    call_ids = 5:9;
elseif strcmp(which_calls, 'pup')
    N_call_types = 5;
    call_ids = 0:4;
end

    

cmap = colormap(ax,'parula');
color_ind = round(linspace(1,256,N_call_types));
vector_len = 30;

for i=1:N_call_types
    ind = find(squeak_data.call_types == call_ids(i));
    for c=1:length(ind)
        curFrame = squeak_data.call_frames(ind(c));
        if curFrame <= length(gaze_data.bino_gaze_outer_wall)
            plot(DLC_raw_table_top.nose_x(curFrame), DLC_raw_table_top.nose_y(curFrame),'x',...
                'Color',cmap(color_ind(i),:),'LineWidth',10)
            gaze_ang = gaze_data.bino_gaze_outer_wall(curFrame);
            if ~isnan(gaze_ang)
                [x,y] = pol2cart(gaze_ang,vector_len);
                quiver(DLC_raw_table_top.nose_x(curFrame), DLC_raw_table_top.nose_y(curFrame), x, y, ...
                    'Color',cmap(color_ind(i),:),'LineWidth',2,'AutoScale','off','MaxHeadSize',1.5)
            end
        end
    end
end

cbar = colorbar(ax,'Ticks',linspace(0,1,N_call_types),'TickLabels',strsplit(num2str(call_ids)));
cbar.Label.String = 'Call type';


hold('off');
