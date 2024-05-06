%{
# imaging_run
-> sln_symphony.Dataset
image_fname : varchar(128)
---
frame_rate                  : float     #frame rate of the video (Hz)
n_frames                    : int unsigned    #number of frames
width                       : int unsigned    #number of pixels
height                      : int unsigned    #number of pixels
res_x                       : float           # microns per pixel x
res_y                       : float           # microns per pixel y
alignment_fname = null      : varchar(128) #file with alignment pulses, in same folder as image_fname
preprocessing_steps = null  : varchar(512) # comma separated list of (FIJI) preprocessing steps 
%}

classdef ImagingRun < dj.Manual
    methods
        function insert(self, key)
            %key will be the primary key of the associated dataset
            cellname = fetch1(sln_cell.CellName & key, 'cell_name');
            basedir = [getenv('Func_imaging_folder') filesep 'SingleOrPairedCell' filesep cellname filesep];
            disp('Select functional imaging data tif stack.');
            image_fname = uigetfile('*.tif','Select functional imaging data tif stack.',basedir);
            disp('Select associated alignment pulses tif stack.');
            alignment_fname = uigetfile('*.tif','Select associated alignment pulses tif stack.',basedir);
            disp('Select associated metadata .mat file.');
            [meta_data_fname, meta_data_path] = uigetfile('*.mat','Select associated metadata .mat file.',basedir);

            if all(meta_data_fname == false)
                disp('Nothing inserted. Metadata required.');
                return;
            end
            load([meta_data_path filesep meta_data_fname],'SI');
            key.frame_rate = SI.hRoiManager.scanFrameRate;

            preprocessing_steps = inputdlg('List preprocessing steps (e.g. motion correction) (comma separated) or leave blank.',...
                'Preprocessing steps',...
                [1 60], ...
                {''});
            if ~isempty(preprocessing_steps)
                preprocessing_steps = preprocessing_steps{1};
            end
            if all(image_fname == false)
                disp('Nothing inserted. Image filename required.');
                return;
            end

            info = imfinfo([basedir image_fname]);
            key.n_frames = length(info);
            key.width = info(1).Width;
            key.height = info(1).Height;
            key.res_x = 1./info(1).XResolution;
            key.res_y = 1./info(1).YResolution;
            key.image_fname = image_fname;                
            
            if ~all(alignment_fname == false)
                key.alignment_fname = alignment_fname;
            end
            if ~isempty(preprocessing_steps)
                key.preprocessing_steps = preprocessing_steps;
            end            
            insert@dj.Manual(self, key);
            disp('Insert successful.');
        end
    end
end