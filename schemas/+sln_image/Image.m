%{
# An image - confocal, widefield, or 2P. Can be a stack, but not a time series
image_id: int unsigned auto_increment
---
image_filename : varchar(128)
-> sln_lab.Scope
-> sln_lab.User
x_scale : float #microns per pixel
y_scale : float #microns per pixel
z_scale = NULL : float #microns per slice (null if 2D image)
width : smallint unsigned
height : smallint unsigned 
n_channels : tinyint unsigned
n_slices : smallint unsigned
raw_image : blob@raw #the actual raw data 
zoom_factor : float #read in from image metadata
(ch1_type) -> [nullable] sln_image.ChannelType
(ch2_type) -> [nullable] sln_image.ChannelType
(ch3_type) -> [nullable] sln_image.ChannelType
(ch4_type) -> [nullable] sln_image.ChannelType
%}
classdef Image < dj.Manual
    methods
        % function insert(self, key)
        %     self.insert(key)
        % end
    end

    methods(Static)
        function loadFromFile(filename, varargin)
            key = struct;
            forceZ = false;

            if nargin>=2
                key.scope_name = varargin{1};
            end
            if nargin>=3
                key.user_name = varargin{2};
            end
            if nargin>=4
                key.z_scale = varargin{3};
                forceZ = true;
            end            
            if nargin>=5
                ch1 = varargin{4};
                key.ch1_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch1), 'channel_type_id');
            end
            if nargin>=6
                ch2 = varargin{5};
                key.ch2_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch2), 'channel_type_id');
            end
            if nargin>=7
                ch3 = varargin{6};
                key.ch3_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch3), 'channel_type_id');
            end
            if nargin>=8
                ch4 = varargin{7};
                key.ch4_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch4), 'channel_type_id');
            end

            if endsWith(filename,'.tif')
                meta_fname = strrep(filename,'.tif','_meta.mat');
                if ~exist(meta_fname, 'file')
                    error("Metadata file not found");
                end
                load(meta_fname,'SI');
                key.image_filename = filename;
                key.zoom_factor = SI.hRoiManager.scanZoomFactor;
                N_channels = length(SI.hChannels.channelSave);
                key.n_channels = N_channels;
                rows = SI.hRoiManager.linesPerFrame;
                cols = SI.hRoiManager.pixelsPerLine;
                key.width = cols;
                key.height = rows;
                if isfield(SI,'hStackManager')
                    if ~forceZ
                        key.z_scale = abs(SI.hStackManager.actualStackZStepSize);
                    end
                    N_slices = SI.hStackManager.actualNumSlices;
                else
                    N_slices = 1;
                end
                key.n_slices = N_slices;
                key.raw_image = uint16(zeros(rows, cols, N_slices, N_channels));
                raw_image_interleaved = uint16(zeros(rows, cols, N_slices*N_channels));
                fprintf('Loading %d slices * %d channels\n', N_slices, N_channels);
                for i=1:N_slices*N_channels
                    raw_image_interleaved(:,:,i) = imread(filename,i);
                end
                for i=1:N_channels
                    key.raw_image(:,:,:,i) = raw_image_interleaved(:,:,i:N_channels:N_slices*N_channels);
                end
                fprintf('Done loading.\n');
                x_range = abs(SI.hRoiManager.imagingFovUm(1,1) - SI.hRoiManager.imagingFovUm(2,1));
                y_range = abs(SI.hRoiManager.imagingFovUm(2,1) - SI.hRoiManager.imagingFovUm(2,2));
                key.x_scale = x_range / cols; %µm / pixel
                key.y_scale = y_range / rows; %µm / pixel

            elseif endsWith(filename,'.nd2')
                temp = which('BioformatsImage');
                if isempty(temp)
                    error("BioformatsImage not on MATLAB path. Please install toolbox first.");
                end
                im = BioformatsImage(filename);
                key.image_filename = filename;
                key.zoom_factor = 1; %we will just call it zoom factor 1 for .nd2 images
                N_channels = im.sizeC;
                key.n_channels = N_channels;
                rows = im.height;
                cols = im.width;
                key.width = cols;
                key.height = rows;
                key.x_scale = im.pxSize(1);
                key.y_scale = im.pxSize(2);
                N_slices = im.sizeZ;
                key.n_slices = N_slices;
                key.raw_image = uint16(zeros(rows, cols, N_slices, N_channels));
                fprintf('Loading %d slices * %d channels\n', N_slices, N_channels);
                for c=1:N_channels
                    for z=1:N_slices
                        key.raw_image(:,:,z,c) = im.getPlane(z,c,1);
                    end
                end
                fprintf('Done loading.\n');
            else
                error("Image load error: unknown file type");
            end
            insert(sln_image.Image,key);
        end

    end

end