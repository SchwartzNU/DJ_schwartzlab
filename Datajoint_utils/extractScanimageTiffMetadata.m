function [] = extractScanimageTiffMetadata(fname)
if nargin<1
    [fname, fpath] = uigetfile('*.tif','Open ScaneImage Tif...');
    fname = [fpath fname]
end
if ~endsWith(fname,'.tif')
    fname = [fname '.tif'];
end
reader = ScanImageTiffReader.ScanImageTiffReader(fname);
mdata = reader.metadata;
json_part = extractAfter(mdata,"SI.warnMsg = ''");
mdata_struct = jsondecode(json_part);

fname_mat = strrep(fname,'.tif','_meta.mat');
save(fname_mat,'mdata_struct');

Pstim_ROI_groups = struct;
%extract photostim ROI information
if isfield(mdata_struct,'RoiGroups')
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

fname_mat = strrep(fname,'.tif','_pstim_rois.mat');
save(fname_mat,'Pstim_ROI_groups');

