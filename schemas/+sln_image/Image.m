%{
# An image - confocal, widefield, or 2P. Can be a stack, but not a time series
image_id: int unsigned auto_increment
---
image_filename : varchar(128)
folder : varchar(512) #folder from which it was imported, but likely has local parts of the path
creation_date : date #from file when loaded. might not be right
size_in_bytes : int unsigned # from file when loaded, used as part of a check for same files
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
                if ~isempty(varargin{3})
                    key.z_scale = varargin{3};
                    forceZ = true;
                end
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

            file_info = dir(filename);
            key.creation_date = datestr(file_info.datenum,'yyyy-mm-dd');
            key.size_in_bytes = file_info.bytes;
            key.folder = file_info.folder;
            [~, name, ext] = fileparts(filename);
            key.image_filename = [name ext];                

            if endsWith(filename,'.tif')
                meta_fname = strrep(filename,'.tif','_meta.mat');
                if ~exist(meta_fname, 'file')
                    error("Metadata file not found");
                end
                load(meta_fname,'SI');

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
                if ~isfield(key, 'z_scale')
                    entry = inputdlg('Enter z_scale (µm / pixel) or leave blank for 2D image','Z scale',[1 60]);
                    if ~isempty(entry)
                        key.z_scale = str2num(entry{1});
                    end
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
                if ~isfield(key, 'z_scale')
                    entry = inputdlg('Enter z_scale (µm / pixel) or leave blank for 2D image','Z scale',[1 60]);
                    if ~isempty(entry)
                        key.z_scale = str2num(entry{1});
                    end
                end
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
            fprintf('Inserting.\n');
            insert(sln_image.Image,key);
            fprintf('Done.\n');
        end

        function loadFromStitchedFile(filename, varargin)
            key = struct;
            forceZ = false;

            if nargin>=2
                key.scope_name = varargin{1};
            end
            if nargin>=3
                key.user_name = varargin{2};
            end
            if nargin>=4
                if ~isempty(varargin{3})
                    key.z_scale = varargin{3};
                    forceZ = true;
                end
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

            [~, name, ext] = fileparts(filename);
            key.image_filename = [name ext];  

            if endsWith(filename,'.tif')
                meta_fname = strrep(filename,'.tif','_meta.mat');
                SI_meta = true;
                if ~exist(meta_fname, 'file')
                    fprintf("Metadata file not found. Trying to find _part.nd2 instead\n");                    
                    SI_meta = false;
                    nd2_part_fname = strrep(filename,'_stitched','_part');
                    nd2_part_fname = strrep(nd2_part_fname,'.tif','.nd2');
                    if ~exist(nd2_part_fname,'file')
                        error('.nd2 part file not found.');
                    end
                end
                info = imfinfo(filename);
                rows = info(1).Height;
                cols = info(1).Width;
                key.width = cols;
                key.height = rows;

                if SI_meta
                    load(meta_fname,'SI');
                    key.zoom_factor = SI.hRoiManager.scanZoomFactor;
                    N_channels = length(SI.hChannels.channelSave);
                    part_rows = SI.hRoiManager.linesPerFrame;
                    part_cols = SI.hRoiManager.pixelsPerLine;
                    key.n_channels = N_channels;

                    if isfield(SI,'hStackManager')
                        if ~forceZ
                            key.z_scale = abs(SI.hStackManager.actualStackZStepSize);
                        end
                    end
                    if ~isfield(key, 'z_scale')
                        entry = inputdlg('Enter z_scale (µm / pixel) or leave blank for 2D image','Z scale',[1 60]);
                        if ~isempty(entry)
                            key.z_scale = str2num(entry{1});
                        end
                    end
                    N_slices = length(info)/N_channels;
                    key.n_slices = N_slices;
                    x_range = abs(SI.hRoiManager.imagingFovUm(1,1) - SI.hRoiManager.imagingFovUm(2,1));
                    y_range = abs(SI.hRoiManager.imagingFovUm(2,1) - SI.hRoiManager.imagingFovUm(2,2));
                    key.x_scale = x_range / part_cols; %µm / pixel
                    key.y_scale = y_range / part_rows; %µm / pixel
                else
                    temp = which('BioformatsImage');
                    if isempty(temp)
                        error("BioformatsImage not on MATLAB path. Please install toolbox first.");
                    end
                    im = BioformatsImage(nd2_part_fname);
                    key.zoom_factor = 1; %we will just call it zoom factor 1 for .nd2 images
                    N_channels = im.sizeC;
                    key.n_channels = N_channels;
                    key.x_scale = im.pxSize(1);
                    key.y_scale = im.pxSize(2);
                    N_slices = im.sizeZ;
                    key.n_slices = N_slices;
                end

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
            else
                error("Image load error: unknown file type");
            end
            fprintf('Inserting.\n');
            insert(sln_image.Image,key);
            fprintf('Done.\n');
        end

        function is_in_db = inDB(file_info)
            %file_info is a struct from the 'dir' command
            match = sln_image.Image & ...
                sprintf('image_filename="%s"', file_info.name) & ...
                sprintf('creation_date="%s"', datestr(file_info.datenum,'yyyy-mm-dd')) & ...
                sprintf('size_in_bytes=%d', file_info.bytes);
            if match.exists
                is_in_db = true;
            else
                is_in_db = false;                
            end
        end

    end

end