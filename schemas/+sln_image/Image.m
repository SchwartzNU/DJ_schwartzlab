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
        function [match_found, this_unid] = assignToTissue(self, animal_id, tissue_type)
            switch tissue_type
                case 'L eye'
                    thisEye = sln_animal.Eye & sprintf('animal_id=%d', animal_id) & 'side="Left"';
                case 'R eye'
                    thisEye = sln_animal.Eye & sprintf('animal_id=%d', animal_id) & 'side="Right"';
                case 'Brain'
                    disp('Not implemeted yet.');
            end
            
            if ~thisEye.exists
                fprintf('Inserting eyes for animal %d\n',animal_id);
                key = struct;
                key.animal_id = animal_id;
                key.side = 'Left';
                insert(sln_animal.Eye,key);
                key.side = 'Right';
                insert(sln_animal.Eye,key);
                switch tissue_type
                    case 'L eye'
                        thisEye = sln_animal.Eye & sprintf('animal_id=%d', animal_id) & 'side="Left"';
                    case 'R eye'
                        thisEye = sln_animal.Eye & sprintf('animal_id=%d', animal_id) & 'side="Right"';
                end
            end
            cells_for_this_eye = sln_cell.RetinalCell & thisEye;
            q = sln_cell.RetinalCell * proj(sln_cell.RetinaQuadrant) * sln_cell.CellName & proj(cells_for_this_eye);
            match_found = false;
            if q.exists %try to associate with existing cell                
                fname = fetch1(self,'image_filename');
                q_struct = fetch(q,'cell_name');
                for i=1:length(q_struct)
                    pattern = sprintf('%s[^0-9]', q_struct(i).cell_name);
                    if regexp(fname, pattern)%contains(fname, q_struct(i).cell_name)
                        fprintf('matched image %s to cell %s\n', fname, q_struct(i).cell_name)
                        key = struct;
                        key.cell_unid = q_struct(i).cell_unid;
                        key.image_id = fetch1(self,'image_id');
                        match_found = true;
                        insert(sln_image.RetinalCellImage,key);  
                        this_unid = key.cell_unid;
                    end
                end
            end
            if ~match_found %we make a new cell
                key = struct;
                key.animal_id = animal_id;
                disp('inserting new Cell');
                insert(sln_cell.Cell, key);
                thisCell_struct = fetch(sln_cell.Cell & sprintf('animal_id=%d', animal_id) & 'LIMIT 1 PER animal_id ORDER BY cell_unid DESC');
                key.cell_unid = thisCell_struct.cell_unid;
                key.side = fetch1(thisEye,'side');
                disp('inserting new RetinalCell');
                %TODO add x and y position
                insert(sln_cell.RetinalCell,key);
                key = struct;
                key.cell_unid = thisCell_struct.cell_unid;
                this_unid = key.cell_unid;
                key.image_id = fetch1(self,'image_id');
                disp('inserting image match to RetinalCell');
                insert(sln_image.RetinalCellImage,key);
            end
        end
    end

    methods(Static)
        function LoadFromFilewithStructuralInput(filename, user_name, scope_name, channel_arr, z_scale)%input struct should contain: scope, user, each type of the 4 channels, z scale
            arguments
                filename 
                user_name 
                scope_name 
                channel_arr
                z_scale = NaN
            end
            %checking keys
            try
                n_input_channels = numel(channel_arr);
                if (n_input_channels==0)
                    error("No channel information input!");
                end
                for c = 1:numel(channel_arr)
                    fieldName = sprintf('ch%d_type', c);
                    channel = channel_arr{c};
                    if (isa(channel, "double") || isa(channel, "int16") || isa(channel, "unit8"))
                        q = append('channel_type_id=', num2str(channel));
                    elseif (isa(channel, 'string'))
                        q = append('channel_type_id=', channel);
                        channel = str2double(channel);
                    elseif (isa(channel, "char"))
                        q = append('channel_type_id=', convertCharsToStrings(channel));
                        channel = str2num(channel);
                    else
                        error('Channel %d cannot be recognized: type %s!\n', c, class(channel))
                    end

                    if (~exists(sln_image.ChannelType & q))
                        error('Channel type not existed yet! please check or fill out sln_image.ChannelType!\n');
                    end

                    key.(fieldName) = channel;
                end
                key.user_name = user_name;
                key.scope_name = scope_name;
                if (~isnan(z_scale))
                    key.z_scale = z_scale;
                end
                file_info = dir(filename);
                key.creation_date = datestr(file_info.datenum,'yyyy-mm-dd');
                key.size_in_bytes = file_info.bytes;
                key.folder = file_info.folder;
                [~, name, ext] = fileparts(filename);
                key.image_filename = strcat(name, ext);

                if endsWith(filename,'.tif')
                    meta_fname = strrep(filename,'.tif','_meta.mat');
                    if ~exist(meta_fname, 'file')
                        error("Metadata file not found");
                    end

                    mdloading = load(meta_fname);
                    SI = mdloading.meta;
                    
                    if (~isprop(SI, 'hRoiManager'))
                        key.zoom_factor = 1;
                    else
                        key.zoom_factor = SI.hRoiManager.scanZoomFactor;
                    end
                    
                    N_channels = SI.sizeC;
                    if N_channels ~= n_input_channels
                        error('Number of channels mismatch: %d provided but %d found in file.\n', n_input_channels, N_channels);
                    end
                    key.n_channels = N_channels;
                    key.width = SI.width;
                    key.height = SI.height;
                    
                    if (isprop(SI, 'sizeZ'))
                         key.n_slices = SI.sizeZ;
                    else
                        key.n_slices = 1;
                    end
                   
                    key.raw_image = uint16(zeros(key.height, key.width, key.n_slices, N_channels));
                    raw_image_interleaved = uint16(zeros(key.height, key.width, key.n_slices*N_channels));
                    fprintf('Loading %d slices * %d channels\n', key.n_slices, N_channels);
                    for i=1:key.n_slices*N_channels
                        raw_image_interleaved(:,:,i) = imread(filename,i);
                    end
                    for i=1:N_channels
                        key.raw_image(:,:,:,i) = raw_image_interleaved(:,:,i:N_channels:key.n_slices*N_channels);
                    end
                    fprintf('Done loading.\n');
                    if (isprop(SI, 'hRoiManager') || isfield(SI, 'hRoiManager'))
                        x_range = abs(SI.hRoiManager.imagingFovUm(1,1) - SI.hRoiManager.imagingFovUm(2,1));
                        y_range = abs(SI.hRoiManager.imagingFovUm(2,1) - SI.hRoiManager.imagingFovUm(2,2));
                        key.x_scale = x_range / key.height; %µm / pixel
                        key.y_scale = y_range / key.width; %µm / pixel
                    else
                        key.x_scale = SI.pxSize(1);
                        key.y_scale = SI.pxSize(2);
                    end



                elseif endsWith(filename,'.nd2')
                    temp = which('BioformatsImage');
                    if isempty(temp)
                        error("BioformatsImage not on MATLAB path. Please install toolbox first.");
                    end
                    im = BioformatsImage(filename);
                    key.zoom_factor = 1; %we will just call it zoom factor 1 for .nd2 images
                    N_channels = im.sizeC;
                    if N_channels ~= n_input_channels
                        error('Number of channels mismatch: %d provided but %d found in file.\n', n_input_channels, N_channels);
                    end
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
                fprintf('Inserting.\n');
                insert(sln_image.Image,key);
                %insertingfinish = 1;
                fprintf('Done.\n');
            catch ME
                fprintf('Uploaded failed!')
                rethrow(ME);
            end
        end

        function loadFromFile(filename, varargin)
            key = struct;
            forceZ = false;
            n_input_channels = 0;

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
                n_input_channels = 1;
            end
            if nargin>=6
                ch2 = varargin{5};
                key.ch2_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch2), 'channel_type_id');
                n_input_channels = 2;
            end
            if nargin>=7
                ch3 = varargin{6};
                key.ch3_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch3), 'channel_type_id');
                n_input_channels = 3;
            end
            if nargin>=8
                ch4 = varargin{7};
                key.ch4_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch4), 'channel_type_id');
                n_input_channels = 4;
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
                if N_channels ~= n_input_channels
                    error('Number of channels mismatch: %d provided but %d found in file.\n', n_input_channels, N_channels);
                end
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
                if N_channels ~= n_input_channels
                    error('Number of channels mismatch: %d provided but %d found in file.\n', n_input_channels, N_channels);
                end
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
            n_input_channels = 0;

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
                n_input_channels = 1;
            end
            if nargin>=6
                ch2 = varargin{5};
                key.ch2_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch2), 'channel_type_id');
                n_input_channels = 2;
            end
            if nargin>=7
                ch3 = varargin{6};
                key.ch3_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch3), 'channel_type_id');
                n_input_channels = 3;
            end
            if nargin>=8
                ch4 = varargin{7};
                key.ch4_type = fetch1(sln_image.ChannelType & sprintf('channel_content="%s"', ch4), 'channel_type_id');
                n_input_channels = 4;
            end

            file_info = dir(filename);
            key.creation_date = datestr(file_info.datenum,'yyyy-mm-dd');
            key.size_in_bytes = file_info.bytes;
            key.folder = file_info.folder;
            [~, name, ext] = fileparts(filename);
            key.image_filename = [name ext];  

            if endsWith(filename,'.tif')
                meta_fname = strrep(filename,'.tif','_meta.mat');
                SI_meta = true;
                if ~exist(meta_fname, 'file')
                    meta_fname = strrep(filename,'_stitched.tif','_part_meta.mat');
                    if ~exist(meta_fname, 'file')
                        fprintf("Metadata file not found. Trying to find _part.nd2 instead\n");
                        SI_meta = false;
                        nd2_part_fname = strrep(filename,'_stitched','_part');
                        nd2_part_fname = strrep(nd2_part_fname,'.tif','.nd2');
                        if ~exist(nd2_part_fname,'file')
                            error('.nd2 part file not found.');
                        end
                    end
                end
                info = imfinfo(filename);
                rows = info(1).Height;
                cols = info(1).Width;
                key.width = cols;
                key.height = rows;varchar(512)

                if SI_meta
                    load(meta_fname,'SI');
                    key.zoom_factor = SI.hRoiManager.scanZoomFactor;
                    N_channels = length(SI.hChannels.channelSave);
                    if N_channels ~= n_input_channels
                        fprintf('Number of channels mismatch in part image: %d provided but %d found in file.\n', n_input_channels, N_channels);
                        fprintf('Forcing to match input for stitched image\n');
                        N_channels = n_input_channels;
                    end
                    part_rows = SI.hRoiManager.linesPerFrame;
                    part_cols = SI.hRoiManager.pixelsPerLine;

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
                    if N_channels ~= n_input_channels
                        fprintf('Number of channels mismatch in part image: %d provided but %d found in file.\n', n_input_channels, N_channels);
                        fprintf('Forcing to match input for stitched image\n');
                        N_channels = n_input_channels;
                    end
                    key.x_scale = im.pxSize(1);
                    key.y_scale = im.pxSize(2);
                    N_slices = im.sizeZ;
                    key.n_slices = N_slices;
                end
                N_slices = length(info)/N_channels;
                key.n_slices = N_slices;
                key.n_channels = N_channels;
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
            key
            insert(sln_image.Image,key);
            fprintf('Done.\n');
        end

        function match = get_db_match(file_info)
            %file_info is a struct from the 'dir' command
            match = sln_image.Image & ...
                sprintf('image_filename="%s"', file_info.name) & ...
                sprintf('creation_date="%s"', datestr(file_info.datenum,'yyyy-mm-dd')) & ...
                sprintf('size_in_bytes=%d', file_info.bytes);            
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