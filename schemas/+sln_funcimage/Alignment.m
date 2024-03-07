%{
# Functional Imaging Alignment between epochs and image segments
-> sln_funcimage.ImagingRun
---
alignment_entry_time = CURRENT_TIMESTAMP : timestamp # when this was entered into db
%}
classdef Alignment < dj.Computed
    properties
        keySource = sln_funcimage.ImagingRun
    end

    methods(Access=protected)
        function makeTuples(self, key)
            cellname = fetch1(sln_cell.CellName & key, 'cell_name');
            basedir = [getenv('Func_imaging_folder') filesep 'SingleOrPairedCell' filesep cellname filesep];
            image_props = fetch(sln_funcimage.ImagingRun & key, '*');

            epoch_aligned_dir = [basedir extractBefore(image_props.image_fname, '.tif'), '_epochAligned'];
            if ~isfolder(epoch_aligned_dir)
                mkdir(epoch_aligned_dir);
            end

            epochs = sln_symphony.DatasetEpoch * sln_symphony.ExperimentEpoch & key;
            
            V = zeros(image_props.height, image_props.n_frames);
            for i=1:image_props.n_frames
                frame = imread([basedir image_props.alignment_fname],i);
                V(:,i) = mean(frame,2);
            end
            V_flat = reshape(V,[image_props.height*image_props.n_frames, 1]);

            alignment_pulse_trace = V_flat-min(V_flat);
            alignment_pulse_trace = alignment_pulse_trace./max(alignment_pulse_trace);
            pulses_up = getThresCross(alignment_pulse_trace, 0.5, 1);
            
            if epochs.count ~= length(pulses_up)
                fprintf('Alignment error: number of alignment pulses (%d) did not match number of epochs (%d). \n', length(pulses_up), epochs.count);
                return;
            end
            keyboard;
            
        end
    end

end