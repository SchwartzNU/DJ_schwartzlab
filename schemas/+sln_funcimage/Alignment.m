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
            try
                pulse_on_stim = true;

                cellname = fetch1(sln_cell.CellName & key, 'cell_name');
                basedir = [getenv('Func_imaging_folder') filesep 'SingleOrPairedCell' filesep cellname filesep];
                image_props = fetch(sln_funcimage.ImagingRun & key, '*');

                epoch_aligned_dir = [basedir extractBefore(image_props.image_fname, '.tif'), '_epochAligned'];
                if ~isfolder(epoch_aligned_dir)
                    mkdir(epoch_aligned_dir);
                end

                epochs = sln_symphony.DatasetEpoch * sln_symphony.ExperimentEpoch & key;
                epochs_struct = fetch(epochs);
                if pulse_on_stim % need to add pre time
                    prot_name = fetch1(sln_symphony.ExperimentEpochBlock & epochs_struct(1),'protocol_name');
                    prot_name = sqlProtName2ProtName(prot_name);
                    example_epoch_params = fetch(aka.EpochParams(prot_name) * aka.BlockParams(prot_name) & epochs_struct(1), '*');
                    pre_time = example_epoch_params(1).pre_time;
                end

                epoch_ids = fetchn(epochs,'epoch_id');
                epoch_durations_ms = fetchn(epochs,'epoch_duration');
                N_epochs = length(epoch_ids);

                V = zeros(image_props.height, image_props.n_frames);
                %func_volume = uint16(zeros(image_props.height, image_props.width, image_props.n_frames));
                disp('Loading images');
                fprintf('%d frames to load.\n', image_props.n_frames);
                for i=1:image_props.n_frames
                    if rem(i,100)==0
                        fprintf('%d of %d frames loaded.\n', i, image_props.n_frames);
                    end
                    frame = imread([basedir image_props.alignment_fname],i);
                    V(:,i) = mean(frame,2);
                    func_volume(:,:,i) = imread([basedir image_props.image_fname],i);
                end
                func_volume = func_volume - 2^15; %OFFSET when you save from FIJI for some reason
                V_flat = reshape(V,[image_props.height*image_props.n_frames, 1]);

                disp('Locating alignment pulses');
                alignment_pulse_trace = V_flat-min(V_flat);
                alignment_pulse_trace = alignment_pulse_trace./max(alignment_pulse_trace);
                pulses_up = getThresCross(alignment_pulse_trace, 0.5, 1);

                if epochs.count ~= length(pulses_up)
                    fprintf('Alignment error: number of alignment pulses (%d) did not match number of epochs (%d). \n', length(pulses_up), epochs.count);
                    error('Alignment error');
                end
                decimal_frames = pulses_up / image_props.height;
                if pulse_on_stim
                    decimal_frames = decimal_frames - (pre_time/1E3) * image_props.frame_rate;
                end
                start_frames = round(decimal_frames);
                offsets = decimal_frames - start_frames;
                offsets_ms = offsets / image_props.frame_rate * 1E3;
                dlmwrite([epoch_aligned_dir, filesep, 'ms_shifts.txt'], [epoch_ids, offsets_ms]);

                info = imfinfo([basedir image_props.image_fname]);

                disp('Writing aligned images to database');

                self.insert(key)
                for i=1:N_epochs
                    end_frame = start_frames(i) + ceil((epoch_durations_ms(i)/1E3)*image_props.frame_rate);

                    % t = Tiff(sprintf('%s%sepoch_%d.tif', epoch_aligned_dir, filesep, epoch_ids(i)), 'w');
                    % setTag(t,'Photometric',Tiff.Photometric.MinIsBlack);
                    % setTag(t,'Compression',Tiff.Compression.None);
                    % setTag(t,'BitsPerSample',info(1).BitDepth);
                    % setTag(t,'SamplesPerPixel',end_frame - start_frames(i) + 1);
                    % setTag(t,'SampleFormat',Tiff.SampleFormat.UInt);
                    % setTag(t,'ExtraSamples',Tiff.ExtraSamples.Unspecified);
                    % setTag(t,'ImageLength',image_props.height);
                    % setTag(t,'ImageWidth',image_props.width);
                    % planarConfig = info(1).PlanarConfiguration;
                    % setTag(t,'PlanarConfiguration',Tiff.PlanarConfiguration.(planarConfig));
                    % write(t, func_volume(:,:,start_frames(i):end_frame));
                    % close(t);

                    key_epoch_movie = key;
                    key_epoch_movie = mergeStruct(key_epoch_movie, epochs_struct(i));
                    key_epoch_movie.offset_ms = round(offsets_ms(i));
                    key_epoch_movie.raw_movie = func_volume(:,:,start_frames(i):end_frame);
                    insert(sln_funcimage.EpochMovie,key_epoch_movie);
                end
                disp('Insert successful.');
            catch ME
                disp('Alignment insert failed because of error:');
                disp(ME.message);
                rethrow(ME);
            end
<<<<<<< HEAD
            func_volume = func_volume - 2^15; %OFFSET when you save from FIJI for some reason
            V_flat = reshape(V,[image_props.height*image_props.n_frames, 1]);

            disp('Locating alignment pulses');
            alignment_pulse_trace = V_flat-min(V_flat);
            alignment_pulse_trace = alignment_pulse_trace./max(alignment_pulse_trace);
            pulses_up = getThresCross(alignment_pulse_trace, 0.5, 1);
            
            if epochs.count ~= length(pulses_up)
                fprintf('Alignment error: number of alignment pulses (%d) did not match number of epochs (%d). \n', length(pulses_up), epochs.count);
                return;
            end
            decimal_frames = pulses_up / image_props.height;
            if pulse_on_stim
                decimal_frames = decimal_frames - (pre_time/1E3) * image_props.frame_rate;
            end
            start_frames = round(decimal_frames);
            offsets = decimal_frames - start_frames;
            offsets_ms = offsets / image_props.frame_rate * 1E3;            
            dlmwrite([epoch_aligned_dir, filesep, 'ms_shifts.txt'], [epoch_ids, offsets_ms]);

            info = imfinfo([basedir image_props.image_fname]);

            disp('Writing aligned images to database');    
            
            self.insert(key)
            for i=1:N_epochs
                end_frame = start_frames(i) + ceil((epoch_durations_ms(i)/1E3)*image_props.frame_rate);
%                 if end_frame > size(func_volume,3)
% %                     end_frame = size(func_volume,3); %option 1: cut the epoch short
%                     continue %option 2: drop the epoch
%                 end
                % option 3: figure out why this happened, prevent it from
                % happening again, decide on option1/2 for this case once
                % we understand more

                % t = Tiff(sprintf('%s%sepoch_%d.tif', epoch_aligned_dir, filesep, epoch_ids(i)), 'w');
                % setTag(t,'Photometric',Tiff.Photometric.MinIsBlack);
                % setTag(t,'Compression',Tiff.Compression.None);
                % setTag(t,'BitsPerSample',info(1).BitDepth);
                % setTag(t,'SamplesPerPixel',end_frame - start_frames(i) + 1);
                % setTag(t,'SampleFormat',Tiff.SampleFormat.UInt);
                % setTag(t,'ExtraSamples',Tiff.ExtraSamples.Unspecified);
                % setTag(t,'ImageLength',image_props.height);
                % setTag(t,'ImageWidth',image_props.width);
                % planarConfig = info(1).PlanarConfiguration;
                % setTag(t,'PlanarConfiguration',Tiff.PlanarConfiguration.(planarConfig));
                % write(t, func_volume(:,:,start_frames(i):end_frame));
                % close(t);

                key_epoch_movie = key;
                key_epoch_movie = mergeStruct(key_epoch_movie, epochs_struct(i));
                key_epoch_movie.offset_ms = round(offsets_ms(i));
                key_epoch_movie.raw_movie = func_volume(:,:,start_frames(i):end_frame);
%                 key_epoch_movie.raw_movie = func_volume(:,:,start_frames(i):min(end_frame, size(func_volume,3)));
               
                insert(sln_funcimage.EpochMovie,key_epoch_movie);
            end   
            disp('Insert successful.');

=======
>>>>>>> e44937e4f37f179b697013c5623f6022110fa274
        end
    end

end