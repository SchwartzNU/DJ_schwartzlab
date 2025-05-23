function [] = extractScanimageTiffMetadata(fname)
if nargin<1
    last_open_path = getpref('extractScanimageTiffMetadata', 'last_open_path', getenv('SERVER_ROOT'));
    file_filter = fullfile(last_open_path, filesep, '*.tif');
    [fname, fpath] = uigetfile(file_filter,'Open ScaneImage Tif...');
    setpref('extractScanimageTiffMetadata', 'last_open_path', fpath);
    fname = [fpath fname]
end
if ~endsWith(fname,'.tif')
    fname = [fname '.tif'];
end
reader = ScanImageTiffReader.ScanImageTiffReader(fname);
mdata = reader.metadata;

% json_part = extractAfter(mdata,"SI.warnMsg = ''");
mdata_lines = splitlines(mdata);
%find problem line
probInd =  find(startsWith(mdata_lines,'SI.hBeams.calibrationMaxCalVoltage'));
if ~isempty(probInd)
    prob = split(mdata_lines(probInd),'=');
    %fix the syntax
    mdata_lines{probInd} = strjoin({prob{1},strjoin({'[',prob{2},']'})}, '=');
end

lastSIindex = find(startsWith(mdata_lines,'SI'),1,'last');
% SI_struct_part = extractBefore(mdata,"SI.warnMsg = ''");
SI_struct_part = strjoin(mdata_lines(1:lastSIindex),'\n');
SI_struct_part = strrep(SI_struct_part,'scanimage.types.BeamAdjustTypes.Exponential','"exponential"');
SI_struct_part = strrep(SI_struct_part, 'scanimage.types.BeamAdjustTypes.None', "'none'");

eval(SI_struct_part); %creates SI struct
json_part = strjoin(mdata_lines(lastSIindex+1:end),'\n');
mdata_struct = jsondecode(json_part);
fname_mat = strrep(fname,'.tif','_meta.mat');
save(fname_mat,'mdata_struct', 'SI');

Pstim_ROI_groups = struct;
%extract photostim ROI information
N_groups = 0;
if isfield(mdata_struct,'RoiGroups')
    if isfield(mdata_struct.RoiGroups, 'photostimRoiGroups')
    N_groups = length(mdata_struct.RoiGroups.photostimRoiGroups);
    for i=1:N_groups
        Pstim_ROI_groups(i).name = mdata_struct.RoiGroups.photostimRoiGroups(i).name;
        rois = mdata_struct.RoiGroups.photostimRoiGroups(i).rois;
        point_ind = 1;
        park_ind = 1;
        for r=1:length(rois)
            roi_type = rois(r).scanfields.stimulusFunction;
            if strcmp(roi_type,'scanimage.mroi.stimulusfunctions.point')
                Pstim_ROI_groups(i).points_x(point_ind) = rois(r).scanfields.centerXY(1);
                Pstim_ROI_groups(i).points_y(point_ind) = rois(r).scanfields.centerXY(2);
                Pstim_ROI_groups(i).points_duration_s(point_ind) = rois(r).scanfields.duration;
                Pstim_ROI_groups(i).points_power(point_ind) = rois(r).scanfields.powers;
                point_ind = point_ind+1;
             elseif strcmp(roi_type,'scanimage.mroi.stimulusfunctions.park')
                Pstim_ROI_groups(i).parks_duration_s(park_ind) = rois(r).scanfields.duration;
                Pstim_ROI_groups(i).parks_power(park_ind) = rois(r).scanfields.powers;
                park_ind = park_ind+1;
            end
        end
    end
    end
end

if N_groups>0
fname_mat = strrep(fname,'.tif','_pstim_rois.mat');
save(fname_mat,'Pstim_ROI_groups');
end

