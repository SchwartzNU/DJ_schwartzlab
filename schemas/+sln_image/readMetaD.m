%dependency: download Bio-Format matlab toolbox at https://downloads.openmicroscopy.org/bio-formats/5.5.3/

%raw ND2 file path in fp
fp ='C:\Users\Zhang\OneDrive - Northwestern University\Xin_Greg\Data\RetrogradeTracing\ID3021\c13\0514_zstack_594_647_c013.nd2';
%Note: z stack step is not accurate from the metadata, this part of codes
%should not be used
%data = bfopen(fp);
%metadata = data{1, 2};
%step = metadata.get('Global - step');
%stepN = str2double(strsplit(step));

image = BioformatsImage(fp);

%use other BioformatsImage to read other information:
metaStruct.width = image.width;
metaStruct.height = image.height;
metaStruct.sizeZ = image.sizeZ;
metaStruct.sizeC = image.sizeC;
metaStruct.sizeT = image.sizeT;
metaStruct.xpixel = image.pxSize(1);
metaStruct.ypixel = image.pxSize(2);
metaStruct.pxUnits = image.pxUnits;
metaStruct.bitDepth = image.bitDepth;

%dump the struct
save('metaData.mat', 'metaStruct');