classdef SpikeDetectorGUI_DB < handle
    properties
        fig
        handles
        mode
        threshold
        spikeTimes
        data
        loaded_cell
        epochIndicesList
        curEpochListIndex
        sampleRate
        channel_name
        epochsInDataSets
        spikeFilter
        filteredData
        noiseLevel
        cellname
    end
    
    methods
        function obj = SpikeDetectorGUI_DB(cellname, params, channel_name)            
            if nargin < 3
                obj.channel_name = 'Amp1';
            else
                obj.channel_name = channel_name;
            end
            if nargin < 2
                params.spikeDetectorMode = 'advanced';
                params.spikeThreshold = -9;
            end
            
            obj.cellname = cellname;
            
            % to generate the spike filter, do:
%             spikeFilter = designfilt('bandpassiir', 'StopbandFrequency1', 200, 'PassbandFrequency1', 300, 'PassbandFrequency2', 3000, 'StopbandFrequency2', 3500, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 10000);
%             save('SymphonyAnalysis/utilities/spikeFilter.mat', 'spikeFilter')

            sf = load('spikeFilter.mat'); %in Datajoint_utils
            obj.spikeFilter = sf.spikeFilter;

            s.file_name = cellname(1:7);
            s.rig_name = cellname(7);
            s.cell_number = str2double(cellname(9:end));
            q = sln_symphony.Experiment * sln_symphony.ExperimentCell & s;
            if ~q.exists
                errordlg(sprintf('%s not found', cellname));
            elseif q.count > 1
                errordlg(sprintf('%s: more than 1 matching cell', cellname));
            else
                obj.loaded_cell = q;
            end

            obj.mode = params.spikeDetectorMode;
            obj.threshold = params.spikeThreshold;
            obj.curEpochListIndex = 1;

            q = sln_symphony.ExperimentElectrode * sln_symphony.DatasetEpoch & ...
                (sln_symphony.ExperimentCell * aka.Dataset & proj(obj.loaded_cell)) & ...
                sprintf('channel_name="%s"',obj.channel_name) & 'amp_mode="Cell attached"';
            if q.exists
                obj.epochIndicesList = sort(unique(fetchn(q,'epoch_id')));
            else
                error('No cell-attached dataset epochs found, may need curation');
            end

            %obj.initializeEpochsInDataSetsList();
            
            obj.buildUI();
            
            obj.loadCurrentEpochResponse();
            obj.updateUI();            
        end
        
        function buildUI(obj)
            obj.fig = figure( ...
                'Name',         ['Spike Detector: Epoch ' num2str(obj.epochIndicesList(obj.curEpochListIndex))], ...
                'NumberTitle',  'off', ...
                'Menubar',      'none', ...                         
                'ToolBar',      'none',...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));

            L_main = uix.VBox('Parent', obj.fig);
            
            L_info = uix.HBox('Parent', L_main, ...
                'Spacing', 2);
            
            obj.handles.autoSaveCheckbox = uicontrol('Parent', L_info, ...
                'Style', 'checkbox', ...
                'String', 'Autosave', ...
                'Value', true, ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.saveNowButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Save & Sync', ...
                'Callback', @(uiobj, evt)obj.autoSave(true), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));            
            
            uicontrol('Parent', L_info, ...
                'Style', 'text', ...
                'String', 'Spike detector mode');
            obj.handles.detectorModeMenu = uicontrol('Parent', L_info, ...
                'Style', 'popupmenu', ...
                'String', {'Standard deviations above noise', 'Simple threshold', 'advanced'});
            switch obj.mode
                case 'Stdev'
                    set(obj.handles.detectorModeMenu, 'value', 1);
                case 'threshold'
                    set(obj.handles.detectorModeMenu, 'value', 2);
                case 'advanced'
                    set(obj.handles.detectorModeMenu, 'value', 3);
            end
            uicontrol('Parent', L_info, ...
                'Style', 'text', ...
                'String', 'Threshold:');
            obj.handles.thresholdEdit = uicontrol('Parent', L_info, ...
                'Style', 'edit', ...
                'String', num2str(obj.threshold), ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.reDetectButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', 'FontWeight', 'bold', 'FontSize', 14, ...
                'String', 'Detect spikes', ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.clearSpikesButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Clear spikes', ...
                'Callback', @(uiobj, evt)obj.clearSpikes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.clickThresholdButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Click Threshold', ...
                'Callback', @(uiobj, evt)obj.clickThreshold(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));            
            obj.handles.selectValidSpikesButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Select valid region', ...
                'Callback', @(uiobj, evt)obj.selectValidSpikes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            
            
            L_plotBox = uix.VBoxFlex('Parent', L_main);
            obj.handles.primaryAxes = axes('Parent', L_plotBox, ...
                'ButtonDownFcn', @axisZoomCallback);
            obj.handles.secondaryAxes = axes('Parent', L_plotBox);
            L_plotBox.Heights = [-1, -1];
            
            bottomButtonBlock = uix.HBox('Parent', L_main);
            obj.handles.applyToAllButton = uicontrol('Parent', bottomButtonBlock, ...
                'Style', 'pushbutton', ...
                'String', 'Apply to all', ...
                'Callback', @(uiobj, evt)obj.updateAllSpikeTimes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.applyToFutureButton = uicontrol('Parent', bottomButtonBlock, ...
                'Style', 'pushbutton', ...
                'String', 'Apply to this & future', ...
                'Callback', @(uiobj, evt)obj.updateFutureSpikeTimes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.skipBackward10 = uicontrol('Parent', bottomButtonBlock, ...
                'Style', 'pushbutton', ...
                'String', 'Back 10', ...
                'Callback', @(uiobj, evt)obj.skipBackward10(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.skipForward10 = uicontrol('Parent', bottomButtonBlock, ...
                'Style', 'pushbutton', ...
                'String', 'Forward 10', ...
                'Callback', @(uiobj, evt)obj.skipForward10(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            
            set(L_main, 'Heights', [50, -1, 50]);
            set(L_info, 'Widths', [-.8, -.8, -.8, -1.5, -.8, -.6, -2, -1, -1, -1]);
        end
        
        function detectSpikes(obj, index)
             ep = aka.Epoch * sln_symphony.ExperimentChannel & obj.loaded_cell & ...
                sprintf('channel_name="%s"',obj.channel_name) & ...
                sprintf('epoch_id=%d', obj.epochIndicesList(index));

            % get response for this epoch
            [~, response] = sln_symphony.getEpochRawData(ep,obj.channel_name);
            response = response - mean(response);
%            response = response';

            % get detection config
            ind = get(obj.handles.detectorModeMenu, 'value');
            s = get(obj.handles.detectorModeMenu, 'String');
            obj.mode = s{ind};
            obj.threshold = str2double(get(obj.handles.thresholdEdit, 'String'));

            if strcmp(obj.mode, 'Simple threshold')
                spikeIndices = getThresCross(response, obj.threshold, sign(obj.threshold));

                % refine spike locations to tips
                if obj.threshold < 0
                    for si = 1:length(spikeIndices)
                        sp = spikeIndices(si);
                        if sp < 100 || sp > length(response) - 100
                            continue
                        end
                        while response(sp) > response(sp+1)
                            sp = sp+1;
                        end
                        while response(sp) > response(sp-1)
                            sp = sp-1;
                        end
                        spikeIndices(si) = sp;
                    end
                else
                    for si = 1:length(spikeIndices)
                        sp = spikeIndices(si);
                        if sp < 100 || sp > length(response) - 100
                            continue
                        end
                        while response(sp) < response(sp+1)
                            sp = sp+1;
                        end
                        while response(sp) < response(sp-1)
                            sp = sp-1;
                        end
                        spikeIndices(si) = sp;
                    end
                end

            elseif strcmp(obj.mode, 'advanced')
                [fresponse, noise] = obj.filterResponse(response);
                spikeIndices = getThresCross(fresponse, noise * obj.threshold, sign(obj.threshold));

                % refine spike locations to tips
                if obj.threshold < 0
                    for si = 1:length(spikeIndices)
                        sp = spikeIndices(si);
                        if sp < 100 || sp > length(response) - 100
                            continue
                        end
                        while response(sp) > response(sp+1)
                            sp = sp+1;
                        end
                        while response(sp) > response(sp-1)
                            sp = sp-1;
                        end
                        spikeIndices(si) = sp;
                    end
                else
                    for si = 1:length(spikeIndices)
                        sp = spikeIndices(si);
                        if sp < 100 || sp > length(response) - 100
                            continue
                        end
                        while response(sp) < response(sp+1)
                            sp = sp+1;
                        end
                        while response(sp) < response(sp-1)
                            sp = sp-1;
                        end
                        spikeIndices(si) = sp;
                    end
                end

            else 
                spikeResults = SpikeDetector_simple(response, 1./obj.sampleRate, obj.threshold);
                spikeIndices = spikeResults.sp;
            end

            %remove double-counted spikes
            if length(spikeIndices) >= 2
                ISItest = diff(spikeIndices);
                spikeIndices = spikeIndices([(ISItest > (0.001 * obj.sampleRate)) true]);
            end

            if index == obj.curEpochListIndex
                obj.spikeTimes = spikeIndices; % for plotting now
            end

            %write the spike train to the database
            key = fetch(ep);
            key.spike_count = length(spikeIndices);
            key.spike_indices = spikeIndices;
            insert(sln_symphony.SpikeTrain, key, 'replace');

            % save spikes in the epoch
%             if strcmp(obj.streamName, 'Amplifier_Ch1')
%                 channel = 'spikes_ch1';
%             else
%                 channel = 'spikes_ch2';
%             end
% 
%             epoch.attributes(channel) = spikeIndices;

        end
        
        
        function updateSpikeTimes(obj)
            obj.detectSpikes(obj.curEpochListIndex);
            
            %obj.autoSave();         
            
            obj.updateUI();
        end
        
        function updateAllSpikeTimes(obj)           
            for index = 1:length(obj.epochIndicesList)
                set(obj.fig, 'Name', sprintf('Detecting spikes: epoch %g', obj.epochIndicesList(index)));
                drawnow;
                obj.detectSpikes(index);
            end
            
            obj.autoSave();
            
            obj.updateUI();
        end

        function updateFutureSpikeTimes(obj)
            for index=1:length(obj.epochIndicesList)
                
                if index < obj.curEpochListIndex
                    continue
                end
                set(obj.fig, 'Name', sprintf('Detecting spikes: epoch %g', obj.epochIndicesList(index)));
                drawnow;
                obj.detectSpikes(index);
            end
            
            obj.autoSave();
            
            obj.updateUI();
        end
        
        function autoSave(obj, force)
            if nargin == 1
                force = false;
            end
            if force || obj.handles.autoSaveCheckbox.Value
                set(obj.fig, 'Name', 'Saving');
                drawnow;
                %saveAndSyncCellData(obj.cellData);
                %set(obj.fig, 'Name', 'Saved');
                %drawnow;
            end
        end
        
        function loadCurrentEpochResponse(obj)
            ep = aka.Epoch * sln_symphony.ExperimentChannel & obj.loaded_cell & ...
                sprintf('channel_name="%s"',obj.channel_name) & ...
                sprintf('epoch_id=%d', obj.epochIndicesList(obj.curEpochListIndex));

            [~, obj.data] = sln_symphony.getEpochRawData(ep,obj.channel_name);
            epoch = fetch(ep,'*');
            obj.sampleRate = epoch.sample_rate;
            obj.data = obj.data - mean(obj.data);
            %obj.data = obj.data';
            [obj.filteredData, obj.noiseLevel] = obj.filterResponse(obj.data);
            
            %load spike times if they are present
            q = sln_symphony.SpikeTrain & ep;
            if q.exists
                loadedSpikes = fetch1(q,'spike_indices');
            else
                loadedSpikes = nan;
            end
            
            needToGetSpikes = isnan(loadedSpikes) & length(loadedSpikes) == 1;
            if needToGetSpikes
                %obj.updateSpikeTimes();
            else
                obj.spikeTimes = loadedSpikes;
            end
            
            obj.updateUI();
        end
        
        function clearSpikes(obj)
            obj.spikeTimes = [];

            epoch = obj.cellData.epochs(obj.epochIndicesList(obj.curEpochListIndex));
            if strcmp(obj.streamName, 'Amplifier_Ch1')
                channel = 'spikes_ch1';
            else
                channel = 'spikes_ch2';
            end
            
            epoch.attributes(channel) = obj.spikeTimes;
        
            obj.autoSave();
            
            obj.updateUI();
            
        end
        
        function clickThreshold(obj)
            [~,y] = ginput(1);
            ax = gca();
            if(ax == obj.handles.primaryAxes)
                obj.mode = 'Simple threshold';
                set(obj.handles.detectorModeMenu, 'Value', 2);
            elseif(ax == obj.handles.secondaryAxes)
                obj.mode = 'advanced';
                set(obj.handles.detectorModeMenu, 'Value', 3);
                y = y;% / obj.noiseLevel;
            else
                return
            end
                
            obj.threshold = y;
%             obj.mode = 'Simple threshold';
            set(obj.handles.thresholdEdit, 'String', num2str(obj.threshold, 2));
%             set(obj.handles.detectorModeMenu, 'Value', 2);
            obj.updateSpikeTimes()
        end
        
        function selectValidSpikes(obj)
            selection = getrect(obj.handles.primaryAxes);
            times = obj.spikeTimes / obj.sampleRate;
            amps = obj.data(obj.spikeTimes);

            selectX = times > selection(1) & times < selection(1) + selection(3);
            selectY = amps > selection(2) & amps < selection(2) + selection(4);
            
            obj.spikeTimes(~(selectX & selectY)) = [];
            
            epoch = obj.cellData.epochs(obj.epochIndicesList(obj.curEpochListIndex));
            if strcmp(obj.streamName, 'Amplifier_Ch1')
                channel = 'spikes_ch1';
            else
                channel = 'spikes_ch2';
            end
            
            epoch.attributes(channel) = obj.spikeTimes;
            
            obj.autoSave();
            
            obj.updateUI();
        end
        

        
        function skipBackward10(obj)
            obj.curEpochListIndex = max(obj.curEpochListIndex-10, 1);
            obj.loadCurrentEpochResponse();
        end
        function skipForward10(obj)
            obj.curEpochListIndex = min(obj.curEpochListIndex+10, length(obj.epochIndicesList));
            obj.loadCurrentEpochResponse();
        end
        
        function initializeEpochsInDataSetsList(obj)
           k = obj.cellData.savedDataSets.keys;
           for i=1:length(k)
               obj.epochsInDataSets = [obj.epochsInDataSets obj.cellData.savedDataSets(k{i})];
           end
        end
        
        function updateUI(obj)
            if isempty(obj.data)
                disp('empty response')
                cla(obj.handles.primaryAxes)
                drawnow
                return
            end
            t = (0:length(obj.data)-1) / obj.sampleRate;
            plot(obj.handles.primaryAxes, t, obj.data, 'k');
            hold(obj.handles.primaryAxes, 'on');
            plot(obj.handles.primaryAxes, t(obj.spikeTimes), obj.data(obj.spikeTimes), 'ro', 'MarkerSize', 10, 'linewidth', 2);
            if strcmp(obj.mode, 'Simple threshold')
                xax = xlim(obj.handles.primaryAxes);
                line(xax, [1,1]*obj.threshold, 'LineStyle', '-', 'Color', 'g', 'Parent', obj.handles.primaryAxes);
            end
            title(obj.handles.primaryAxes, 'Raw data');
            hold(obj.handles.primaryAxes, 'off');
            xlim(obj.handles.primaryAxes, [min(t), max(t)+eps]);
            
            % advanced filtered plot
            plot(obj.handles.secondaryAxes, t, obj.filteredData / obj.noiseLevel, 'k');
            hold(obj.handles.secondaryAxes, 'on');
            plot(obj.handles.secondaryAxes, t(obj.spikeTimes), obj.filteredData(obj.spikeTimes) / obj.noiseLevel, 'ro', 'MarkerSize', 10, 'linewidth', 2);
            xax = xlim(obj.handles.secondaryAxes);
            
            line(xax, 1*[1,1], 'LineStyle', '--', 'Color', 'r', 'Parent', obj.handles.secondaryAxes);
            line(xax, -1*[1,1], 'LineStyle', '--', 'Color', 'r', 'Parent', obj.handles.secondaryAxes);
            if strcmp(obj.mode, 'advanced')
                line(xax, obj.threshold*[1,1], 'LineStyle', '-', 'Color', 'g', 'Parent', obj.handles.secondaryAxes);
            end
%             legend(obj.handles.secondaryAxes, 'test', 'Location', 'Best')
            hold(obj.handles.secondaryAxes, 'off');
            title(obj.handles.secondaryAxes, 'Filtered version for advanced detector');
            xlim(obj.handles.secondaryAxes, [min(t), max(t)]);
            
            displayName = obj.cellname;
            set(obj.fig, 'Name',['Spike Detector: Epoch ' num2str(obj.epochIndicesList(obj.curEpochListIndex)) ' (' displayName '): ' num2str(length(obj.spikeTimes)) ' spikes, ' obj.channel_name]);
            drawnow
        end
        
        function [fdata, noise] = filterResponse(obj, fdata)
            if isempty(fdata)
                noise = [];
                return
            end
            fdata = [fdata(1) + zeros(1,2000), fdata, fdata(end) + zeros(1,2000)];
            fdata = filtfilt(obj.spikeFilter, fdata);
            fdata = fdata(2001:(end-2000));
            noise = median(abs(fdata) / 0.6745);
        end
        
        
        function keyHandler(obj, evt)
            switch evt.Key
                case 'leftarrow'
                    obj.curEpochListIndex = max(obj.curEpochListIndex-1, 1);
                    obj.loadCurrentEpochResponse();
                case 'rightarrow'
                    obj.curEpochListIndex = min(obj.curEpochListIndex+1, length(obj.epochIndicesList));
                    obj.loadCurrentEpochResponse();
                case 'escape'
                    delete(obj.fig);
                otherwise
                    %disp(evt.Key);
            end
        end
        
    end
    
end