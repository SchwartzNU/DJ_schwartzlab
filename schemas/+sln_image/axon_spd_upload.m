function axon_spd_upload(folder)
%a function to upload the spinning disk z stack images of RGC axons in the brain
% upload first into sln_image.Image, then add annotation to sln_image.AxonInBrain
infofile = fullfile(folder, 'info.txt');
if (~isfile(infofile))
    fprintf('In folder %s ', folder);
    error('cannot find info.txt file!\n');
end

%extracting information from info.txt file
fid = fopen(infofile);
data = textscan(fid, '%s %s', 'Delimiter', ':');
fclose(fid);
img_keys = strtrim(data{1});
img_values = strtrim(data{2});

img_id = find(strcmp(img_keys, 'image_id'));
if (isempty(img_id))
    fprintf('Image in folder %s has not been uploaded, uploading now...\n', folder);
    %find the .nd2 file
allfiles = dir(folder);
nd2 = '';
nd2_count = 0; %in case 2 .nd2 files exist in the same folder...
for i = 1:numel(allfiles)
    cur_f = allfiles(i).name;

    if (endsWith(cur_f, '.nd2'))
        nd2_count  = nd2_count+1;
        nd2 = cur_f;
    end
end

if (nd2_count~=1)
    error('No nd2 file or multiple nd2 file in the folder, please check!\n')
end

shift_idx = find(strcmp(img_keys, 'shift'));
if (isempty(shift_idx))
    error('The info txt does not contain channel color shift info.\n')
end
shift = img_values(shift_idx);
if (shift == "true" )
    %image has color shift and need to upload .tif file but first make bioinformats meta data file
    shiftname_ext_idx = find(strcmp(img_keys, 'shift_filename_ext'));
    if (isempty(shiftname_ext_idx))
        error('Cannot find shift information in infor.txt. Please check.\n');
    end
    shift_format_idx = find(strcmp(img_keys, 'shift_fileformat'));
    if(isempty(shift_format_idx))
        error('Cannot find new image file format afte shift in info.txt. Please check\n');
    end
        nameparts = string(split(nd2, '.'));
    temp = img_values(shiftname_ext_idx);
   % nameaddon = temp{1};
    nameparts(1) = nameparts(1) + string(temp{1});
    temp= img_values(shift_format_idx);
    nameparts(2) =  temp{1};
    newname = nameparts(1)+'.'+nameparts(2);
    img_path = fullfile(folder, newname);

    if(~isfile(img_path))
        fprintf('Cannot find file %s in the folder %s', newname, folder);
        error('Shift image cannot be found.');
    end
     %make meta data file
    fprintf('Generating meta file for .tif uploading...\n');
    meta = BioformatsImage(char(fullfile(folder, nd2)));
    meta_fname = nameparts(1)+'_meta' + '.mat';
    meta_path = fullfile(folder, meta_fname);
    save(meta_path, "meta");
    fprintf('Done.\n');
else
    %if no shift happens, use .nd2 file instead
    img_path = fullfile(folder, nd2);
end

    %
        user = img_values(find(strcmp(img_keys, 'user')));
        user = user{1};
        channel_num = img_values(find(strcmp(img_keys, 'channel_num')));
        channel_num = int16(str2double(channel_num{1}));
        scope = img_values(find(strcmp(img_keys, 'scope')));
        scope  = scope{1};
        zscale = img_values(find(strcmp(img_keys, 'zscale')));
        zscale = str2double(zscale{1});

        channels = cell(channel_num, 1);
        for i=1:channel_num
            channels{i} = 3;
        end

        %query for the image id
        imdj.user_name = user;
        imdj.scope = scope;
        imlist = fetch(sln_image.Image & imdj);
        new_to_old = sort([imlist.image_id], 'descend');
        %upload the image to the sln_image.Image
        sln_image.Image.LoadFromFilewithStructuralInput(img_path, user, scope, channels, zscale);
        this_id = new_to_old(1);
        fid = fopen(infofile, 'a');
        fprintf(fid, 'image_id:%d\n', this_id);
        fclose(fid);
else
    fprintf('image in folder %s has been uploaded, image id: %d\n', folder, str2num( img_values{img_id}));
end
    
        %TODO finish sln_image.AxonInBrain uploading part
        %insert the image to table sln_image.AxonInBrain
        fprintf('Now inserting to table sln_image.AxonInBrain....\n');
        ml_idx = find(strcmp(img_keys, 'ml'));
        ap_idx = find(strcmp(img_keys, 'ap'));
        if (isempty(ml_idx) || isempty(ap_idx))
            fprintf('Either ml or ap not in the info.txt file. please check...\n');
        else
            ml = str2double( img_values{ml_idx});
            ap = str2double( img_values{ap_idx});
            image_idx = find(strcmp(img_keys, 'image_id'));
            image_id = str2double(img_values(image_idx));
            wholebrain_idx = find(strcmp(img_keys, 'ref_image_id'));
            wholebrain_id =str2double(img_values(wholebrain_idx));
            cx_idx = find(strcmp(img_keys, 'centroid_x'));
            cx = str2double(img_values(cx_idx));
            cy_idx = find(strcmp(img_keys, 'centroid_y'));
            cy =str2double( img_values(cy_idx));
            background = fullfile(folder, 'background.roi');
            mask = fullfile(folder, 'mask.tif');

            
            sln_image.AxonInBrain.assign_axon_in_brain(image_id, wholebrain_id,cx, cy, 100, background, mask, ml, ap);
        end
end