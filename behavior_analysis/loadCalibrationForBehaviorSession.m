function [] = loadCalibrationForBehaviorSession(folder_name)
session_id = matchBehaviorFolder(folder_name);
top_camera_serial = '17391304';

if isnan(session_id)
    disp('Calibration load failed');
    return;
end

key = struct;
key.session_id = session_id;
key.inches_per_pixel = 0.022031; %measued by Alec on 7/7/21

%read wall radii from config_behavior_rig.toml
fname = [folder_name filesep 'config' filesep 'config_behavior_rig.toml'];
flines = readlines(fname);
for i=1:length(flines)
    curLine = flines{i};
    if startsWith(curLine, 'inner_r =')
        c = strsplit(curLine, '=');
        key.inner_wall_radius = str2double(c{2});
    elseif startsWith(curLine, 'outer_r_ =')
        c = strsplit(curLine, '=');
        key.outer_wall_radius_top = str2double(c{2});
    elseif startsWith(curLine, '#outer_r =')
        c = strsplit(curLine, '=');
        key.outer_wall_radius_bottom = str2double(c{2});
    end
end

%read center and window positions from config_alignment_17391304.toml
fname = [folder_name filesep 'config' filesep 'config_alignment_' top_camera_serial '.toml'];
flines = readlines(fname);
for i=1:length(flines)
    curLine = flines{i};
    if startsWith(curLine, 'recorded_center =')
        c = strsplit(curLine, '=');
        centerPos = str2num(c{2});
        key.center_position_x = centerPos(1);
        key.center_position_y = centerPos(2);
    elseif startsWith(curLine, 'A1 =')
        c = strsplit(curLine, '=');
        A1pos = str2num(c{2});
    elseif startsWith(curLine, 'A2 =')
        c = strsplit(curLine, '=');
        A2pos = str2num(c{2});
     elseif startsWith(curLine, 'B1 =')
        c = strsplit(curLine, '=');
        B1pos = str2num(c{2});
    elseif startsWith(curLine, 'B2 =')
        c = strsplit(curLine, '=');
        B2pos = str2num(c{2});
     elseif startsWith(curLine, 'C1 =')
        c = strsplit(curLine, '=');
        C1pos = str2num(c{2});
    elseif startsWith(curLine, 'C2 =')
        c = strsplit(curLine, '=');
        C2pos = str2num(c{2});        
    end
end

theta_A1 = atan2((A1pos(2)-centerPos(2)),(A1pos(1)-centerPos(1)));
theta_A2 = atan2((A2pos(2)-centerPos(2)),(A2pos(1)-centerPos(1)));
theta_B1 = atan2((B1pos(2)-centerPos(2)),(B1pos(1)-centerPos(1)));
theta_B2 = atan2((B2pos(2)-centerPos(2)),(B2pos(1)-centerPos(1)));
theta_C1 = atan2((C1pos(2)-centerPos(2)),(C1pos(1)-centerPos(1)));
theta_C2 = atan2((C2pos(2)-centerPos(2)),(C2pos(1)-centerPos(1)));

thetaA_min = min([theta_A1, theta_A2]);
thetaA_max = max([theta_A1, theta_A2]);

thetaB_min = min([theta_B1, theta_B2]);
thetaB_max = max([theta_B1, theta_B2]);

thetaC_min = min([theta_C1, theta_C2]);
thetaC_max = max([theta_C1, theta_C2]);

key.windowa_start = thetaA_min;
key.windowa_end = thetaA_max;
key.windowb_start = thetaB_min;
key.windowb_end = thetaB_max;
key.windowc_start = thetaC_min;
key.windowc_end = thetaC_max;

insert(sl.BehaviorSessionCalibration, key);
end


