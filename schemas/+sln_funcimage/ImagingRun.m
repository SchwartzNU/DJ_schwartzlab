%{
# imaging_run
-> sln_symphony.Dataset
image_fname : varchar(128)
---
frame_rate                  : float     #frame rate of the video (Hz)
n_frames                    : int unsigned    #number of frames
alignment_fname = null      : varchar(128) #file with alignment pulses, in same folder as image_fname
preprocessing_steps = null   : varchar(512) # comma separated list of (FIJI) preprocessing steps 
%}

classdef ImagingRun < dj.Manual
    methods
        function insert(self, key)
            %key will be the primary key of the associated dataset
            cellname = fetch1(sln_cell.CellName & key, 'cell_name');
            basedir = [getenv('Func_imaging_folder') filesep 'SingleOrPairedCell' filesep cellname filesep]
            image_fname = uigetfile('*.tif','Select functional imaging data tif stack.',basedir)
            alignment_fname = uigetfile('*.tif','Select associated alignment pulses tif stack.',basedir)
            
            preprocessing_steps = inputdlg('List preprocessing steps (e.g. motion correction) (comma separated) or leave blank.',...
                'Preprocessing steps',...
                [1 60], ...
                {''})
            preprocessing_steps = preprocessing_steps{1};
            if all(image_fname == false)
                disp('Nothing inserted. Image filename required.');
                return;
            else
                key.image_fname = image_fname;                
            end
            if ~all(alignment_fname == false)
                key.alignment_fname = alignment_fname;
            end
            if ~isempty(preprocessing_steps)
                key.preprocessing_steps = preprocessing_steps;
            end            
            self.insert(key);
            keyboard;
        end
    end
end