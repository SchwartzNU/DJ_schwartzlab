classdef BioformatsImage
    % BIOFORMATSIMAGE  MATLAB implementation of the BioformatsImage package
    %
    %   OBJ = BIOFORMATSIMAGE(FILENAME) creates a new BioformatsImage
    %   object to read an image file. This class uses the Bioformats
    %   toolbox, a standalone Java library for reading and writing life
    %   sciences image formats developed by the Open Microscopy Environment
    %   team (http://www.openmicroscopy.org). Whenever an object is
    %   created, it will check if the toolbox exists. If it does not, it
    %   will download and install a compatible version to the MATLAB path.
    %
    %   I = getPlane(OBJ, ZPLANE, CHANNEL, TIME) will return a grayscale
    %   image at the z-plane, channel, and time coordinates specified. To
    %   get the number of planes, see the list of properties below.
    %
    %   TS = getTimestamps(OBJ, ZPLANE, CHANNEL) will return the timestamps
    %   for all frames of the image at the specified z-plane and channel.
    %   The timestamps can be used to compute the time between frames e.g.
    %   by using diff(TS).
    %
    %   I = getFalseColor(OBJ, ZPLANE, CHANNEL, TIME) will return a false
    %   color image using the lookup table in the file metadata. If this
    %   information does not exist, a warning will be issued and the
    %   grayscale image will be returned instead.
    %
    %   I = getPlane(OBJ, ..., 'ROI', RECT) will return a sub-image based
    %   on the rectangular coordinates specified. RECT should be a 1x4
    %   vector specifying [XMIN, YMIN, WIDTH, HEIGHT] values.
    %
    %   I = getTile(OBJ, ZPLANE, CHANNEL, TIME, NUMTILES, TILEIND) allows
    %   large images to be read out as tiles. NUMTILES should be a 1x2
    %   vector specifying the number of tiles [rows cols] the image should
    %   be split into. TILEIND specifies which tile should be read out.
    %
    %   BioformatsImage Properties:
    %   ---------------------------
    %
    %     filename - Path to image file. Note: If this value is changed,
    %                the other properties will change to reflect the values
    %                in the new file.
    %     width - Width of the image in pixels (equal to number of
    %             columns)
    %     height - Height of the image in pixels (equal to number of rows)
    %     series - Currently selected series (usually indicates XY points)
    %     seriesCount - Number of series in image
    %     sizeZ - Number of z-planes in image
    %     sizeC - Number of channels in iamge
    %     sizeT - Number of timepoints (frames) in image
    %     channelNames - List of channel names
    %     pxSize - Specifies [x, y] size of pixels in physical units
    %     pxUnits - Units of physical pixel dimension
    %     bitDepth - Number of bits in image
    %     lut - Lookup table (columns are image intensity, rows are color)
    %     swapZandT - If true, swaps the z and t values in the image
    %
    %  BioformatsImage Methods:
    %  ------------------------
    %
    %     getPlane - Get image from coordinates specified
    %     getFalseColor - Get false color image using embedded lookup table
    %     getTimestamps - Get vector of timestamps for frames specified
    %     getTile - Split image into sub images and return a tile
    %
    %  Examples:
    %
    %  %Create a new object and display an image
    %  bfr = BIOFORMATSIMAGE('cameraman.tif');
    %  I = getPlane(bfr, 1, 1, 1);
    %  imshow(I, [])

    properties (AbortSet)   %Filename
        filename = '';
    end

    properties (Dependent)  %Image file attributes
        width
        height

        series
        seriesCount

        sizeZ   %Number of z-planes
        sizeC   %Number of channels
        sizeT   %Number of timepoints

        channelNames

        pxSize
        pxUnits

        bitDepth
        lut

    end

    properties

        swapZandT logical = false; %Workaround for split z-planes

    end

    properties (Transient, Hidden, SetAccess = private)
        cleanup
        bfReader
        metadata
        globalMetadata
        seriesMetadata
    end

    properties (Access = private)   %Bioformats toolbox download URL
        bfTbxURL = 'http://downloads.openmicroscopy.org/bio-formats/5.7.1/artifacts/bfmatlab.zip';
    end

    %--- Main methods ---%

    methods %Constructor, getters and setters

        function obj = BioformatsImage(varargin)
            % Create a new class object
            %
            % R = BIOFORMATSIMAGE(filename) returns the object in R.

            %Check if the toolbox exists
            if ~obj.bfTbxExist
                obj.installBFtbx;
            end

            if nargin > 0
                if nargin == 1
                    obj.filename = varargin{1};
                else
                    error('BioformatsImage:TooManyInputArguments',...
                        'Too many input arguments. Was expecting one.')
                end
            end

            obj.cleanup = onCleanup(@()delete(obj));

        end

        function obj = set.filename(obj,filename)

            %Verify that filename is a string
            if ~ischar(filename)
                error('BioformatsImage:FilenameNotString',...
                    'Input filename must be a string.');
            elseif isempty(filename)
                error('BioformatsImage:NoFilename',...
                    'Please specify an image file.');
            end

            %Check that the file exists
            if ~exist(filename,'file')
                error('BioformatsImage:CannotFindFile',...
                    'Could not find %s. Provide the full filename or make sure the image folder is on the MATLAB path.',filename);
            end

            %Make sure that the full path to the file is stored
            [fPath,fName,fExt] = fileparts(filename);

            if ~isempty(fPath)
                %Reconstruct the full path (this will correct any
                %system-dependent file separator strings)
                obj.filename = fullfile(fPath,[fName,fExt]);

            else
                %Since the file must exist on the MATLAB path (we checked
                %this above), we can use which to determine the full path
                %to the file
                obj.filename = which(filename);

            end

            %Get a reader for the image
            obj = obj.getReader;

        end

        function obj = set.series(obj,iS)
            %Set series number

            if isempty(obj.bfReader)
                obj = obj.getReader;
            end

            if rem(iS,1) ~= 0
                error('BioformatsImage:SeriesNumberMustBeInteger',...
                    'Expected series number to be an integer.')
            end

            if iS <= 0 || iS > obj.seriesCount
                error('BioformatsImage:RequestedSeriesOutOfBounds',...
                    'Requested series must be > 0 and <= than %d.',obj.seriesCount);
            end

            obj.bfReader.setSeries(iS - 1);

        end

        function seriesOut = get.series(obj)

            if ~obj.bfReaderExist
                seriesOut = NaN;
            else
                seriesOut = obj.bfReader.getSeries + 1;
            end

        end

        function height = get.height(obj)

            if ~isempty(obj.bfReader)
                height = obj.bfReader.getSizeY;
            end

        end

        function width = get.width(obj)

            if ~isempty(obj.bfReader)
                width = obj.bfReader.getSizeX;
            end

        end

        function sizeZ = get.sizeZ(obj)

            if ~isempty(obj.bfReader)
                if ~obj.swapZandT
                    sizeZ = obj.bfReader.getSizeZ;
                else
                    sizeZ = obj.bfReader.getSizeT;
                end
            end

        end

        function sizeC = get.sizeC(obj)

            if ~isempty(obj.bfReader)
                sizeC = obj.bfReader.getSizeC;
            end

        end

        function sizeT = get.sizeT(obj)

            if ~isempty(obj.bfReader)
                if ~obj.swapZandT
                    sizeT = obj.bfReader.getSizeT;
                else
                    sizeT = obj.bfReader.getSizeZ;
                end
            end

        end

        function seriesCount = get.seriesCount(obj)

            seriesCount = obj.bfReader.getSeriesCount;

        end

        function metadata = get.metadata(obj)

            metadata = obj.bfReader.getMetadataStore;

        end

        function seriesMetadata = get.seriesMetadata(obj)

            seriesMetadata = obj.bfReader.getSeriesMetadata;

        end

        function globalMetadata = get.globalMetadata(obj)

            globalMetadata = obj.bfReader.getGlobalMetadata;
        end

        function chNames = get.channelNames(obj)
            chNames = cell(1,obj.sizeC);

            for iC = 1:obj.sizeC
                chNames{iC} = obj.metadata.getChannelName(0, iC - 1).char;
            end
        end

        function pxSize = get.pxSize(obj)

            pxSizeX = double(obj.metadata.getPixelsPhysicalSizeX(0).value);
            pxSizeY = double(obj.metadata.getPixelsPhysicalSizeY(0).value);

            pxSize = [pxSizeX, pxSizeY];

        end

        function pxUnit = get.pxUnits(obj)

            pxInfoStr = char(obj.metadata.getPixelsPhysicalSizeX(0).toString);

            pxUnit = BioformatsImage.unitStrToChar(pxInfoStr);

        end

        function versionOut = version(obj)

            verStr = ver(class(obj));
            versionOut = verStr.Version;

        end

        function lut = get.lut(obj)
            %Get the lookup table

            %The output of get8BitLookupTable is a SIGNED integer matrix.
            %The values below 0 have to wrapped over e.g. -128 -> -1 for the
            %8-bit data should transform to +128 -> 255. Positive values
            %stay as is.
            if obj.bitDepth == 8
                lut = double(obj.bfReader.get8BitLookupTable);

                lut(lut < 0) = lut(lut < 0) + 255;
                lut = uint8(lut);

            elseif obj.bitDepth == 16
                lut = double(obj.bfReader.get16BitLookupTable);

                lut(lut < 0) = lut(lut < 0) + 65535;
                lut = uint16(lut);

            end

            %Format of LUT is: N x bitDepth



        end

        function bitDepth = get.bitDepth(obj)
            %Get the bit depth of the image
            bitDepth = getValue(obj.metadata.getPixelsSignificantBits(0));
        end

        function delete(obj)
            %DELETE  Close the Bioformats Reader

            if ~isempty(obj.bfReader)
                obj.bfReader.close;
            end

        end

    end

    methods %Base functions

        function [imgOut, timestamp, tsUnits] = getPlane(obj, iZ, iC, iT, varargin)
            %GETPLANE  Get image at specified plane
            %
            %  I = GETPLANE(OBJ, ZPLANE, CHANNEL, TIME) returns a grayscale
            %  image at the z-plane, channel, and time coordinates
            %  specified. Note that these coordinates start at 1 for the
            %  first plane. CHANNEL can either be a number or a string
            %  specifying the channel name (see the 'channelNames'
            %  property).
            %
            %  I = GETPLANE(OBJ, ..., 'ROI', RECT) will return only the
            %  subimage specified by the rectangle RECT = [XMIN, YMIN,
            %  WIDTH, HEIGHT]. ROI stands for 'region of interest'.
            %
            %  I = GETPLANE(OBJ, ZPLANE, CHANNEL, TIME, SERIES) will grab
            %  an image from a different series. Note that this will change
            %  the current series number.
            %
            %  [I, TS, TSUNITS] = GETPLANE(...) will also return the
            %  timestamp TS and its units TSUNITS of the specified image
            %  plane. Note that not all image files will have this
            %  information - if it does not exist, a Java exception (error)
            %  will occur.
            %
            %  Examples:
            %    bfr = BioformatsImage('coloredChips.png');
            %
            %    %Get the red channel (CHANNEL = 1)
            %    R = getPlane(bfr, 1, 1, 1);
            %    figure;
            %    imshow(R);
            %
            %    %Get the blue channel (CHANNEL = 3)
            %    B = getPlane(bfr, 1, 3, 1);
            %    figure;
            %    imshow(B)
            %
            %    %Get a subimage showing the top left corner of the image
            %    I = getPlane(bfr, 1, 1, 1, 'ROI', [1, 1, 100, 100]);
            %    figure;
            %    imshow(I)

            %Parse the variable input argument
            ip = inputParser;
            ip.addOptional('iSeries',NaN,@(x) isnumeric(x) && isscalar(x));
            ip.addParameter('ROI',[],@(x) isempty(x) || (numel(x) == 4 && all(x > 0)));
            ip.parse(varargin{:});

            %Check that reader object already exists
            if ~bfReaderExist(obj)
                %If not, get a reader for the file
                obj = obj.getReader;
            end

            %Change the series (if set)
            if ~isnan(ip.Results.iSeries)
                obj.series = ip.Results.iSeries;
            end

            %Resolve the channel name
            iC = obj.channelname2ind(iC);

            %Get the image
            if ~isempty(ip.Results.ROI)
                xMin = ip.Results.ROI(1);
                yMin = ip.Results.ROI(2);
                roiWidth = ip.Results.ROI(3);
                roiHeight = ip.Results.ROI(4);

                imgOut = bfGetPlane(obj.bfReader,obj.getIndex(iZ, iC, iT),xMin,yMin,roiWidth,roiHeight);

            else
                %Get full image
                imgOut = bfGetPlane(obj.bfReader,obj.getIndex(iZ, iC, iT));

            end

            if nargout > 1
                %Get the timestamp
                [timestamp, tsUnits] = obj.getTimestamps(iZ,iC,iT);
            end

        end

        function [timestamps, tsunits] = getTimestamps(obj, iZ, iC, varargin)
            %GETTIMESTAMPS  Get timestamps from the specified channel
            %
            %  [TS, TSUNITS] = GETTIMESTAMPS(OBj, ZPLANE, CHANNEL) returns
            %  the timestamp information of all frames in the image plane
            %  specified. TS will be a vector with the timestamp of each
            %  frame and TSUNITS will be a string containing the units of
            %  the timestamp.
            %
            %  Note that not all images will contain this data. If the
            %  image does not have timestamp information, a Java exception
            %  (error) will occur.

            ip = inputParser;
            ip.addOptional('TimeRange',Inf,@(x) all(isinf(x)) || isnumeric(x));
            ip.parse(varargin{:});

            %Resolve channel name
            iC = obj.channelname2ind(iC);

            if isinf(ip.Results.TimeRange)
                timeRange = 1:obj.sizeT;
            else
                timeRange = ip.Results.TimeRange;
            end

            %Initialize a vector for the timestamps
            timestamps = zeros(1, numel(timeRange));


            for iT = timeRange
                %Resolve the bioformats index
                bfIndex = obj.getIndex(iZ,iC,iT);

                currTS = obj.metadata.getPlaneDeltaT(obj.series - 1,bfIndex - 1);

                if ~isempty(currTS)
                    timestamps(iT) = double(currTS.value);
                else
                    warning('Timestamp empty');
                    tsunits = '';
                    return;
                end
            end

            %Get the unit string
            tsStr = char(obj.metadata.getPlaneDeltaT(obj.series - 1,bfIndex - 1).toString);

            %Convert the string into a char
            tsunits = BioformatsImage.unitStrToChar(tsStr);

        end

        function [tileDataOut, roiOut] = getTile(obj, iZ, iC, iT, numTiles, tileIndex)
            %GETTILE  Split the image and return a single tile
            %
            %  I = GETTILE(OBJ, ZPLANE, CHANNEL, TIME, NUMTILES, TILEINDEX)
            %  will split the image into the number of tiles specified,
            %  returning the tile at the index specified. This function
            %  could be useful for reading in large image files as the
            %  whole image does not need to be loaded into memory.
            %
            %  NUMTILES should be a 1x2 vector specifying the [NUMROWS,
            %  NUMCOLS] the image should be split into. TILEINDEX should be
            %  a single number indicating the index of the tile to
            %  retrieve. The index follows typical MATLAB convention (i.e.
            %  down rows then columns).
            %
            %  [I, RECT] = GETTILE(...) also returns the rectangle
            %  specifying the subimage returned. RECT = [MINX, MINY, WIDTH,
            %  HEIGHT].
            %
            %  Example:
            %    bfr = BioformatsImage('coloredChips.png');
            %
            %    %Divide the image into 2x2 tiles, displaying each in turn
            %    numTiles = [2, 2];
            %    for tileInd = 1:prod(numTiles)
            %       I = getTile(bfr, 1, 1, 1, numTiles, tileInd);
            %       imshow(I)
            %       title('Press any key to continue.')
            %       pause;
            %    end

            ip = inputParser;
            ip.addRequired('NumTiles',@(x) numel(x) == 2 && all(x > 0));
            ip.addRequired('TileRange', @(x) all(x > 0));
            ip.parse(numTiles,tileIndex);

            %Check that the tile range fits within the total number of
            %tiles
            if any(ip.Results.TileRange > prod(ip.Results.NumTiles))
                error('BioformatsImage:IndexExceedsTileDimensions',...
                    'Index exceeds tile dimensions. Maximum index is %d.',...
                    prod(ip.Results.NumTiles))
            end

            %Create a storage cell (for multiple tile data, which might have different sizes)
            tileDataOut = cell(numel(ip.Results.TileRange),1);

            %Create a storage for the roi
            roiOut = zeros(numel(ip.Results.TileRange),4);

            for iTile = 1:numel(ip.Results.TileRange)
                tileIndex = ip.Results.TileRange(iTile);
                roi = getTileIndices(obj, ip.Results.NumTiles, tileIndex);

                %Get the ROI
                tileDataOut{iT} = obj.getPlane(iZ, iC, iT, 'ROI', roi);
                roiOut(iT,:) = roi;
            end

            %If it's only a single tile, output a matrix rather than a cell
            if numel(tileDataOut) == 1
                tileDataOut = tileDataOut{:};
            end

        end

        function imgOut = getFalseColor(obj, iZ, iC, iT, varargin)
            %GETFALSECOLOR  Get a false (pseudo) color image
            %
            %  I = GETFALSECOLOR(OBJ, ZPLANE, CHANNEL, TIME) will return a
            %  3D matrix representing the color image. The color of the
            %  image is determined by the lookup table (LUT) values written
            %  into the file metadata and might not be present in every
            %  file.
            %
            %  Example:
            %    bfr = BioformatsImage('m83.tif');
            %
            %    %Using getPlane will return a grayscale image
            %    grayI = getPlane(bfr, 1, 1, 1);
            %    imshow(grayI);
            %
            %    %Using getFalseColor, we can get the psuedo-colored image
            %    fcImg = GETFALSECOLOR(bfr, 1, 1, 1);
            %    imshow(fcImg)

            currFrame = obj.getPlane(iZ, iC, iT, varargin{:});

            if isempty(obj.lut)
                warning('BioformatsImage:getFalseColor:NoLUTInfo', ...
                    'The image does not contain lookup table information. Returning the grayscale image instead.');
                imgOut = currFrame;
                return;
            end

            imgOut = zeros([size(currFrame) 3], sprintf('uint%.0d', obj.bitDepth));

            for ii = 1:3
                currLUT = obj.lut(ii,:);
                imgOut(:,:,ii) = currLUT(1 + currFrame);
            end


        end

        function exportAsTIFF(obj, varargin)
            %EXPORTASTIF  Export images as TIFFs
            %
            %  EXPORTASTIFF(OBJ, outputDir) exports images as TIFFs.
            %  Individual channels are exported as individual files. If
            %  outputDir is not supplied, the files will be saved in the
            %  same folder as the input file.

            %Output folder
            if ~isempty(varargin)
                outputDir = varargin{1};
            else
                outputDir = fileparts(obj.filename);
            end

            [~, outputBaseFN] = fileparts(obj.filename);

            %TODO: Series and timepoint export
            for iS = 1:obj.seriesCount

                obj.series = iS;

                for iT = 1:obj.sizeT
                    for iC = 1:obj.sizeC

                        I = getPlane(obj, 1, iC, iT);

                        % %Generate output filename
                        outputFNsuffix = '';
                        if obj.seriesCount > 1
                            outputFNsuffix = [outputFNsuffix, '_s', int2str(iC)];
                        end

                        if obj.sizeC > 1
                            outputFNsuffix = [outputFNsuffix, '_c', int2str(iC)];
                        end

                        if iT == 1
                            imwrite(I, fullfile(outputDir, ...
                                [outputBaseFN, outputFNsuffix, '.tif']), ...
                                'Compression', 'none');
                        else
                            imwrite(I, fullfile(outputDir, ...
                                [outputBaseFN, outputFNsuffix, '.tif']), ...
                                'Compression', 'none', 'writeMode', 'append');
                        end

                    end
                end
            end


        end
    end

    %--- Aux methods ---%

    methods (Access = private, Static)

        function tbxExists = bfTbxExist
            %Check if the BioFormats toolbox is installed

            if ~exist('bfGetReader','file')

                %Check if there is a bfmatlab folder in the toolbox folder

                tbxFolder = fileparts(which('BioformatsImage'));

                if exist(fullfile(tbxFolder,'bfmatlab'),'dir')
                    %Folder exists so add it to the path
                    addpath(fullfile(tbxFolder,'bfmatlab'));
                else
                    tbxExists = false;
                    return;
                end
            end

            tbxExists = true;

        end

        function unitStr = unitStrToChar(strIn)
            %Parses an input string for the unit

            %Find the 'unit[' pattern
            unitStartIdx = strfind(strIn,'unit[');
            %Offset by 5 characters to get start of unit string
            unitStartIdx = unitStartIdx + 5;

            %Find the closing brace, starting from the unit string
            unitEndIdx = strfind(strIn(unitStartIdx:end),']');
            %Reduce by 1 character to not include the closing brace
            unitEndIdx = unitEndIdx - 2;

            %Output the pixel unit
            unitStr = strIn(unitStartIdx: unitStartIdx + unitEndIdx);

        end

    end

    methods (Access = private)

        function obj = getReader(obj)
            %GETREADER  Get a Bioformats Reader object
            %
            % OBJ = GETREADER(OBJ) initializes a reader object using the
            % BioformatsImage java package. The object is stored in the
            % private object bfReader property.

            if ~isempty(obj.filename)
                obj.bfReader = bfGetReader(obj.filename);
            else
                error('BioformatsImage:EmptyFilename',...
                    'Set filename first.');
            end

            %Set current series to 1
            obj.series = 1;

        end

        function installBFtbx(obj)
            %Downloads and installs the Bioformats Toolbox
            %
            % The default install location is the toolbox folder

            tbxFolder = fileparts(which('BioformatsImage'));

            %Create a temporary directory
            if ~exist(fullfile(tbxFolder,'temp'),'dir')
                mkdir(fullfile(tbxFolder,'temp'))
            end

            %Download the toolbox from the OME website
            fprintf('Downloading Bioformats toolbox...');

            fn = websave(fullfile(tbxFolder,'temp','bfmatlab.zip'),obj.bfTbxURL);
            fprintf('Done.\n');

            fprintf('Installing toolbox...')
            %Unzip the toolbox
            unzip(fn,tbxFolder);

            %Add toolbox to path
            addpath(fullfile(tbxFolder,'bfmatlab'))
            fprintf('Done.\n');

            %Remove temporary files and directory
            if exist(fullfile(tbxFolder,'temp'),'dir')
                rmdir(fullfile(tbxFolder,'temp'),'s')
            end

        end

        function bfrExists = bfReaderExist(obj)
            %Checks to see if the bfReader property contains a bfreader
            %object

            if ~isempty(obj.bfReader) && isa(obj.bfReader,'loci.formats.ChannelSeparator')
                bfrExists = true;
            else
                bfrExists = false;
            end

        end

        function chInd = channelname2ind(obj,channelIn)
            %Convert channel name to index

            %If it is already a number, then nothing to do
            if isnumeric(channelIn)
                chInd = channelIn;
                return
            end

            %If it is a cell (happens if iterating over channelNames), then
            %make sure that the cell has a single string entry
            if iscell(channelIn)
                if numel(channelIn) > 1
                    error('BioformatsImage:channelname2ind:TooManyChannels',...
                        'Too many channel names specified at once. Only one channel expected.');
                end

                channelIn = channelIn{1};

            end

            %Find the matching name
            chTF = strcmpi(channelIn, obj.channelNames);

            if ~any(chTF)
                error('BioformatsImage:ChannelNameNotFound',...
                    'Could not find channel %s.',channelIn);
            end

            chInd = find(chTF);

        end

        function roiOut = getTileIndices(obj, numTiles, tileIndex)
            %Given a tile size and index, calculate the resulting ROI
            %vector
            %ROI = [XMIN YMIN WIDTH HEIGHT];

            if numel(tileIndex) == 1
                %If it's a single index, resolve it into row,col
                %coordinates
                [indRow, indCol] = ind2sub(numTiles,tileIndex);
            else
                indRow = tileIndex(1);
                indCol = tileIndex(2);
            end

            %Calculate the tile height/width start and end indices
            %
            % Tile indices are:
            %     start floor(height/numrows) * (tile row number - 1) + 1
            %     end floor(height/numrows) * (tile row number)

            %Row:
            tileHeight = floor(obj.height/numTiles(1));

            rowStart = tileHeight * (indRow - 1) + 1;

            if indRow ~= numTiles(1)
                rowEnd = tileHeight * indRow;
            else
                %If it's the last row, then just use the image height
                rowEnd = obj.height;
            end

            %Convert to ROI height
            roiHeight = rowEnd - rowStart + 1;

            %Col:
            tileWidth = floor(obj.width/numTiles(2));

            colStart = tileWidth * (indCol - 1) + 1;

            if indCol ~= numTiles(2)
                colEnd = tileWidth * indCol;
            else
                %If it's the last row, then just use the image height
                colEnd = obj.width;
            end

            %Convert to ROI width
            roiWidth = colEnd - colStart + 1;

            roiOut = [colStart, rowStart, roiWidth, roiHeight];

        end

        function imgIndex = getIndex(obj, iZ, iC, iT)
            %Get image index from ZCT coordinates.
            if ~obj.swapZandT
                imgIndex = obj.bfReader.getIndex(iZ - 1, iC - 1, iT - 1) + 1;
            else
                imgIndex = obj.bfReader.getIndex(iT - 1, iC - 1, iZ - 1) + 1;
            end
        end

    end

end