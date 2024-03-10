%{
# ROI field
->sln_funcimage.ROIMethod
->sln_funcimage.ImagingRun
---
mask    : longblob # binary mask image
n_rois  : int unsigned 
pixels_in_roi : longblob #cell array with indices of the pixels in each ROI
%}

classdef ROIField < dj.Manual
    methods
        function insert(self,key)
            pixel_thres = 3; %ROIs rejected if they contain less than 3 pixels

            cellname = fetch1(sln_cell.CellName & key, 'cell_name');
            basedir = [getenv('Func_imaging_folder') filesep 'SingleOrPairedCell' filesep cellname filesep];
            disp('Select functional imaging data tif stack.');
            image_fname = uigetfile('*.tif','Select functional imaging data tif stack.',basedir);
            if all(image_fname == false)
                disp('Nothing inserted. Image filename required.');
                return;
            end
            thisImagingRun = sln_funcimage.ImagingRun & sprintf('image_fname="%s"',image_fname);
            if thisImagingRun.exists
                key.image_fname = fetch1(thisImagingRun,'image_fname');
            else
                disp('Nothing inserted. ImagingRun for that image not in database.');
                return;
            end
                  

            app = ROI_method_chooser_dlg;
            waitfor(app,'selection_made',true);
            thisMethod = sln_funcimage.ROIMethod & sprintf('method_name="%s"',app.method_name);
            delete(app);
            
            key.method_id = fetch1(thisMethod,'method_id');
            disp('Select binary mask image.');
            mask_fname = uigetfile('*.tif','Select binary mask image.',basedir);
            if all(mask_fname == false)
                disp('Nothing inserted. Mask file required.');
                return;
            end
            mask = imread([basedir mask_fname]);
            key.mask = mask>0;            
            ROIs = bwconncomp(key.mask,4);
            PixList = [];
            z=1;
            for i=1:ROIs.NumObjects
                currentIDs = ROIs.PixelIdxList{i};
                if length(currentIDs) >= pixel_thres
                    PixList{z} = currentIDs;
                    z=z+1;
                end
            end
            key.pixels_in_roi = PixList;
            key.n_rois = length(PixList);
            insert@dj.Manual(self, key);
            disp('Insert successful.');
        end

        function plot(self)
            self_struct = fetch(self,'*');
            S = size(self_struct.mask);
            M = zeros(S);
            xvals = zeros(self_struct.n_rois,1);
            yvals = zeros(self_struct.n_rois,1);
            for i=1:self_struct.n_rois
                M(self_struct.pixels_in_roi{i}) = i;
                [row, col] = ind2sub(S,self_struct.pixels_in_roi{i});
                xvals(i) = round(mean(col));
                yvals(i) = round(mean(row));
            end
            figure;
            imagesc(M);
            ax = gca;
            colormap(ax,'turbo');
            for i=1:self_struct.n_rois
                text(ax,xvals(i),yvals(i),num2str(i),...
                    'FontWeight','bold','Color',[1 1 1]);                                
            end
        end
    end
end