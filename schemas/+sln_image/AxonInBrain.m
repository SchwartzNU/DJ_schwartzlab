%{
#describe the brain slice 
-> sln_image.Image
---
(whole_brain)->sln_image.WholeBrainImage
medial_lateral: double
distance_from_fist_slice:double
centroid_x: double
centroid_y: double
centroid_radius: double
mask_image: blob@raw
background_roi: blob@raw #2 vertical and 2 horizontal lines that defines the region, PIXEL VALUE
pixel_color: blob@raw
%}

classdef AxonInBrain < dj.Manual
methods (Static)
    %todo: need to add the extract background function.... 
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
    function assign_axon_in_brain(imageid, wholebrainid, cx, cy, r, background, maskpath, color)
        arguments
            imageid
            wholebrainid
            cx
            cy
            r
            background
            maskpath
            color = NaN;
        end
        try
            %basic check to eliminate double insert or no image inserting
            key.image_id = imageid;
           
            query1 = sln_image.Image & key;
            
            if (~exists(query1))
                error('Image not found in the sln_image.Image');
            end
            key.whole_brain = wholebrainid;
            query2 = sln_image.AxonInBrain & key;
            
            if (exists(query2))
                fprintf('Image already annotated!');
                return
            end

            %build other parts of the key
            key.centroid_x = cx;
            key.centroid_y = cy;
            key.centroid_radius = r;
            if (numel(background)~= 4)
                error('Wrong format of the background roi!');
            end
            key.background_roi = background;

            %load the tif mask image
            infopack = imfinfo(maskpath);
            slice_total = numel(infopack);

            im_h = infopack(1).Height;
            im_w = infopack(1).Width;
            mask_ar = uint8(zeros(im_h, im_w, slice_total));
        
            if (isnan(color))
                query.image_id = imageid;
                fprintf('No exisiting pixel value input, extracting now....');
                data = fetch(sln_image.Image & query, 'raw_image');
                %key.color = extract_pixel_color(data.raw_image, background,mask_ar);
                color = {};
                for s = 1:slice_total
                    %loop through all the slices of the z stack image, not
                    %idea but only once
                    %get mask into numeric array and pixel colors
                    mask_ar(:, :, s) = imread(maskpath, index = s);
                    fprintf('filtering slice %d, total %d\n', s, slice_total);
                    color{end+1} = sln_image.AxonInBrain.extract_single_frame(data.raw_image(:, :, s,:), background, mask_ar(:, :, s));
                end
                 %directly load color
            elseif (endsWith(color, 'mat'))
                buffer = load(color);
                if (isvector(buffer))
                    color = buffer;
                else
                    error ('color .mat file content not a vector');
                end
            else
                error('Cannot recognize the format of the color file!')
            end

            key.mask_image = mask_ar;
            key.pixel_color = color;
            C = dj.conn;
            C.startTransaction;
            insert(sln_image.AxonInBrain, key);
            C.commitTransaction;
            fprintf('Insert successful:')
            disp(key)

        catch ME
            rethrow (ME)
        end
    end
end
end