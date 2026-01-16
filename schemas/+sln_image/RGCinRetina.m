%{
#Annotate the high-resolution spinning disk image of a RGC 
->sln_image.Image
-----
background_roi: blob@raw #the 4 lines that defines the background
color_pixel: blob@raw
mask_rgc:blob@raw
%}

classdef RGCinRetina < dj.Manual
methods (Static)
    %centroid needs to be a structure with field: x, y, r. 
    % function image_id = upload_rgc_in_retina(filename, user, scope, channel, z_scale, wholeretina_imid, centroid, cellid,interleave, imageid)
    %     arguments
    %         filename 
    %         user 
    %         scope 
    %         channel 
    %         z_scale 
    %         wholeretina_imid 
    %         centroid 
    %         cellid = NaN;
    % 
    %         interleave = false;
    %         imageid = NaN;
    %     end
    %     try
    %         if (isnan(imageid))
    %             sln_image.Image.LoadFromFilewithStructuralInput(filename, user, scope, channel, z_scale, interleave);
    % 
    %             [folderPath, filepre, fileext] = fileparts(filename);
    %             query = {};
    %             query.image_filename = append(filepre, fileext);
    %             query.folder = folderPath;
    %             query.image_filename = convertStringsToChars(query.image_filename);
    %             query.folder = convertStringsToChars(query.folder);
    %             result = fetch(sln_image.Image & query, 'image_id');
    %             fprintf('RGC image uploaded, image id: %d', result.image_id);
    %             image_id = result.image_id;
    %         else
    %             fprintf('Image already uploaded %d, creating RGC annotation now...\n', imageid);
    %             result.image_id = imageid;
    %         end
    % 
    % 
    %         mask = fullfile(folderPath, 'mask.tif');
    %         if (~isfile(mask))
    %             fprintf('Upload failed, see error message');
    %             error('Cannot find mask file in the folder');
    %         end
    %         %back ground could be either .roi or .mat
    %         background = fullfile(folderPath, 'background.roi');
    %         if (~isfile(background))
    %             background = fullfile(folderPath, 'background.mat');
    %             if (~isfile(background))
    %                 error('Cannot find background file in the same folder as image!');
    %             end
    %         end
    % 
    %         %start uploading sln_image.WholeRetinaImage
    %         if (~isnan(cellid))
    %             fprintf('Inserting spinning disk images for cell: %d', cellid);
    %             sln_image.RGCinRetina.assign_rgc_in_retina(result.image_id, wholeretina_imid, centroid, mask, cellid, background);
    %             fprintf('Sucess!');
    %         else
    %             %creating sln_cell.Cell entries, may cause trouble down the line
    %             query = {};
    %             query.image_id = wholeretina_imid;
    %             mouse = fetch(sln_image.WholeRetinaImage & query, 'animal_id');
    %             %creating cells...
    %             newcell.animal_id = mouse.animal_id;
    %             C = dj.conn;
    %             C.startTransaction;
    %             insert(sln_cell.Cell, newcell);
    %             C.commitTransaction;
    % 
    %             %query the newly inserted cells
    %             cells = fetch(sln_cell.Cell & newcell, 'cell_unid');
    %             [~, idx] = sort([cells.cell_unid], 'descend');
    %             newid = cells(idx(1)).cell_unid;
    %             fprintf('New cell %d created for image %s', newid, filename);
    %             sln_image.RGCinRetina.assign_rgc_in_retina(result.image_id, wholeretina_imid, centroid, mask,newid, background);
    %             fprintf('Image inserted!');
    %         end
    % 
    % 
    %     catch ME
    %         fprintf('uploading rgc image failed!')
    %         rethrow(ME);
    %     end
    % 
    % end
    function pixel_color = extract_single_frame(image_frame, bg_line, mask_frame)
        [row, col] = find(mask_frame~=0);
        indx = sub2ind(size(image_frame), row, col);

        dim = size(image_frame);
        channel_N = dim(end);

        total_nonzero =nnz(mask_frame);
        pixel_color = uint16(zeros(total_nonzero, channel_N));

        for c = 1: channel_N
            channelFrame = reshape(image_frame(:, :, :, c), dim(1), dim(2));
            background = channelFrame(bg_line(1):bg_line(2), bg_line(3):bg_line(4));
            background = mean(background, 'all');
            filteredframe = channelFrame(indx);
            pixel_color(:, c) = filteredframe-background;
        end
    end
    function assign_rgc_in_retina(imageid, cellid, background,  maskpath, color)
        arguments
            imageid               
            cellid 
            background = NaN
            maskpath = NaN
            color = NaN;
        end
        try
            %basic check to eliminate double insert or no image inserting
            key.image_id = imageid;

            query1 = sln_image.Image & key;

            if (~exists(query1))
                error('Image not found in the sln_image.Image, upload first.');
                
            end
            %get background from folder in sln_image.Image if left empty
            imdata = fetch(query1, 'folder');
            if (isnan(background))
                background = fullfile(imdata.folder, 'background.roi');
                if (~isfile(background))
                    error('Cannot find background roi in the folder by table sln_image: %s\n', background);
                end
            end 

            if (isnan(maskpath))
                maskpath = fullfile(imdata.folder, 'mask.tif');
                if (~isfile(maskpath))
                    error('Cannot find mask.tif in folder by sln_image.Image: %s\n', imdata.folder);
                end
            end
           
            %linking image with cell
            assokey.cell_unid = cellid;
            assokey.image_id = imageid;
            asso = fetch(sln_image.RetinalCellImage & assokey);
            C = dj.conn;
            C.startTransaction;

            if (isempty(asso))
                fprintf('Adding new aasociation between cell %d and image %d\n', cellid, imageid);
                insert(sln_image.RetinalCellImage, assokey);
            else
                fprintf('Image and rgc association already exists!\n');
                disk(assokey);
            end

            

           
            if (endsWith(background, '.roi'))
                roi = ReadImageJROI(background);
                if (iscell(roi))
                    roi = roi{1};
                end
                bg_reformt = zeros([1,4]);
                bg_reformt(1) = roi.vnRectBounds(2);
                bg_reformt(2) = roi.vnRectBounds(4);
                bg_reformt(3) = roi.vnRectBounds(1);
                bg_reformt(4) = roi.vnRectBounds(3);
                key.background_roi = bg_reformt;
            elseif (endsWith(background, '.mat'))
                if (numel(background)~= 4)
                    error('Wrong format of the background roi!');
                end
                key.background_roi = background;
            end
          

            %load the tif mask image
            infopack = imfinfo(maskpath);
            slice_total = numel(infopack);

            im_h = infopack(1).Height;
           im_w = infopack(1).Width;
           mask_data =  uint8(zeros(im_h, im_w, slice_total));

            %reduce the value of true pixel in mask to 1
            %mask_ar = mask_ar/max(mask_ar, [], 'all');
            key.maskpath = maskpath;

            if (isnan(color))
                query.image_id = imageid;
                fprintf('No exisiting pixel value input, extracting now....');
                data = fetch(sln_image.Image & query, 'raw_image');
                color = {};
                fprintf( 'total slice to filter: %d\n', slice_total);
                for s = 1:slice_total
                    %loop through all the slices of the z stack image, not
                    %idea but only once
                    %get mask into numeric array and pixel colors
                    maskframe = imread(maskpath, s);
                    mask_data(:, :, s) = imread(maskpath, index = s);
                    
                    color{end+1} = sln_image.RGCinRetina.extract_single_frame(data.raw_image(:, :, s, :), key.background_roi, maskframe);
                    %pixel_color = extract_single_frame(image_frame, bg_line, mask_frame)
                end

            end

            key.color_pixel = color;
            key.mask_rgc = mask_data;
            
            key.cell_unid = cellid;

            insert(sln_image.RGCinRetina, key);
            C.commitTransaction;
            fprintf('Insert successful:')
            disp(key)

        catch ME
            rethrow (ME)
        end

    end
end
end