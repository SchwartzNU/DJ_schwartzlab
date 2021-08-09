%{
# Epoch
-> sl.SymphonyRecordedCell
epoch_number                : int unsigned                  # epoch number
cell_data                   : varchar(128)                  # name of cellData file
---
sample_rate                 : int unsigned                  # samples per second
epoch_start_time            : float                         # seconds since start of cell
protocol_name               : varchar(64)                   # displayName variable name of protocol
protocol_version=NULL       : int unsigned                  # version number of protocol
rstar_mean=NULL             : float                        # background light intensity R*/rod/s
stim_intensity=NULL         : float                        # stimulus intensity R*/rod/s
frame_rate=NULL             : int unsigned                 # frames per second
recording_mode              : enum('Cell attached','Whole cell','U','Off') # recording mode U = unknown
recording2_mode             : enum('Cell attached','Whole cell','U','Off') # recording mode U = unknown
amp_mode                    : enum('Vclamp','Iclamp','U')   # amplifier mode, U = unknown
amp2_mode                   : enum('Vclamp','Iclamp','U')   # amplifier mode, U = unknown
amp_hold=NULL               : float                         # hold signal mV or pA 
amp2_hold=NULL              : float                         # hold signal mV or pA
protocol_params             : longblob                      # struct of protocol parameters
raw_data_filename           : varchar(32)                   # raw data filename without .h5 extension
data_link                   : varchar(512)                  # hdf5 location of raw data - channel 1
data_link2=NULL             : varchar(512)                  # hdf5 location of raw data - channel 2
%}

classdef Epoch < dj.Manual   
    methods

        function [data, xvals, units, protocol_params] = getData(self, channel)
            if nargin < 2
                channel = 1;
            end
            
            data = [];
            xvals = [];
            units = '';
            
            if length(channel) > 1 
                assert(all(channel==1 | channel==2), 'Only channel numbers 1 and 2 are suppported!');
                [dL1,dL2,fnames,sample_rate,protocol_params] = fetchn(self,'data_link', 'data_link2','raw_data_filename','sample_rate','protocol_params');
                assert(length(dL1) == length(channel), 'When providing multiple channels, number of channels must match number of returned epochs!');
                dL = cell(size(dL1));
                dL(channel==1) = dL1(channel==1);
                dL(channel==2) = dL2(channel==2);
            elseif channel == 1
                [dL,fnames,sample_rate,protocol_params] = fetchn(self,'data_link','raw_data_filename','sample_rate','protocol_params');
            elseif channel == 2
                [dL,fnames,sample_rate,protocol_params] = fetchn(self,'data_link2','raw_data_filename','sample_rate','protocol_params');
            else
                disp(['Epoch getData: invalid channel ' num2str(channel)]);
                return;
            end
            
            if isempty(dL)
                disp(['Epoch getData: datalink is empty for channel ' num2str(channel)]);
                return;
            end
            
            [fnames,~,fIndex] = unique(fnames); 
            data = cell(size(dL));
%             xvals = cell(size(dL));
            units = cell(size(dL));
            
            for f = 1:numel(fnames)
                fname = fnames{f};
                fobj = fullfile(getenv('raw_data_folder'), sprintf('%s.h5',fname));
%                 tdL = dL(fIndex==f);
                tIndex = fIndex == f;
%                 for d = 1:numel(tdL)
                for d = find(tIndex)'
%                     temp = h5read(fobj, tdL{d});
                    temp = h5read(fobj, dL{d});
                    data{d} = temp.quantity;
                    if isfield(temp,'units')
                        units{d} = deblank(temp.units(:,1)');
                    else
                        units{d} = deblank(temp.unit(:,1)');
                    end

                    %sampleRate = fetch1(self,'sample_rate');
                    %%temp hack for old data?
                    %if ischar(obj.get('preTime'))
                    %    obj.attributes('preTime') = str2double(obj.get('preTime'));
                    %end        
                    %params = fetch1(self,'protocol_params');
%                     stimStart = params.preTime * 1E-3; %s
%                     if ~isfield(params,'stimStart')
%                         stimStart = 0;
%                     end
%                     xvals = (1:length(data)) / sampleRate - stimStart;
                end
            end
            stimStart = cellfun(@(x) x.preTime * 1e-3, protocol_params);
%             stimStart(cellfun(@(x) ~isfield(x,'stimStart'), protocol_params)) = 0;
%             xvals = (1:length(data)) / sampleRate - stimStart;
            xvals = arrayfun( @(x,y,z) (1:length(x{1}))/y - z, data, sample_rate, stimStart,'uniformOutput',false);
            
            if numel(dL) == 1
               data = data{1};
               xvals = xvals{1};
               units = units{1};
            end
        end
        
    end
end


