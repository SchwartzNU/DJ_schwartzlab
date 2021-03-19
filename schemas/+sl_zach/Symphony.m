%{
# Master table of fully processed Symphony data for a single HDF5 file
# A HDF5 file should enter the database in an 'all-or-none' manner
raw_data_filename : varchar(64)
---
recording_date: date
(experimenter) -> sl.User(user_name)
->sl.Rig
%}
classdef Symphony < dj.Manual
properties (Constant)
  RAW_DATA_FOLDER = getenv('RAW_DATA_FOLDER');
  CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
end

methods
  function [epochs, retinas, recording_date,epoch_groups] = insert(self, key)
    %key structure: 
    %   required: raw_data_filename
    %   optional, but possibly required if unresolvable:
    %     animal_id
    %     cell_unid
    %     cell_data

    disp('inserting from class method')
    [epochs, retinas, recording_date, epoch_groups] = self.loadHDF5(key); %do this for each raw_data_filename

    %first, check that numel(retinas) and numel(fetch(sl.AnimalEventReservedForSession & "date='insertdate'" & "rig='rigname'", "animal_id")) are both 1
    %next check that there are no sl_zach.Cell entries corresponding to that animal and eye
    %if either check fails, throw error that key must be more specific...
   
    %now open the cell data file to get the datasets
    % files = dir(sprintf('%s%s*.mat', self.CELL_DATA_FOLDER, raw_data_filename));
    % for n=1:numel(files)
    %   load(sprintf('%s%s',self.CELL_DATA_FOLDER,files(n).name),'cellData');
    %   check aliases...
    %   [celldata_keys, param_struct] = processCellData...
    %     if empty keys, raise warning
    %     check that number of channels is correct?
    %   %add raw_data_filename, animal_id, cell_unid, cell_data to keys output as appropriate...
    %   %merge across files...
    
    % at this point, we have everything
    %dj.conn.startTransaction()...
    % insert@dj.Manual(self, {key.raw_data_filename, recording_date, retinas.experimenter, rig_name})
    % insert(SymphonyCell, {raw_data_filename, alias, cell_unid, side_eye, pos_x, pos_y, n_epochs, online_label})
    % insert(SymphonyCellDataset, {raw_data_filename, alias, dataset_name})
    % [ind1, remain1] = addParameterGroup(SymphonyProtocolSettings, param_struct);
    % [ind2, remain2] = addParameterGroup(SymphonyEpochSettings, param_struct);
    % [ind3, remain3] = addParameterGroup(SymphonyProjectorSettings, param_struct);
    % assert all(remain1 + remain2 + remain3) == 1
    % keys.epochs(:).protocol_id = ind1;
    % keys.epochs(:).epoch_id = ind2;
    % keys.epochs(:).projector_id = ind3;
    % insert(SymphonyEpoch, {raw_data_filename + keys.epochs})
    % insert(SymphonyEpochChannel, ...)
    % insert(SymphonySpikeTrain, ...)
    % insert(SymphonyCellDatasetEpochs, ...)
  
    % dj.conn.commitTransaction

  end
end

methods (Access=private)
  function [epochs,retinas,recording_date,epochGroups] = loadHDF5(self, raw_data_filename)
    fpath = sprintf('%s%s.h5', self.RAW_DATA_FOLDER, raw_data_filename);

    hinfo = h5info(fpath, '/');

    rinfo = cell2mat(arrayfun( @(x) h5goto(hinfo, x.Value{1}), hinfo.Groups.Groups(5).Links, 'UniformOutput', false));

    NRetinas = numel(rinfo);
    emp = cell(NRetinas, 1);
    retinas = struct('Name',emp, 'genotype',emp, 'orientation', emp, 'experimenter', emp, 'eye', emp, 'cells', emp);

    recording_date = datestr(datetime(uint64(rinfo(1).Attributes(3).Value),'ConvertFrom','.net','timezone',num2str(rinfo(1).Attributes(4).Value)),'YYYY-mm-DD');
    
    NEpochGroups = sum(arrayfun(@(x) length(x.Groups(2).Groups), hinfo.Groups));
    emp = cell(NEpochGroups,1);
    epochGroups = struct('uuid',emp,'label',emp,'blocks',emp,'retina',emp,'cell',emp,'cell_label',emp);
    [epochGroups(:).uuid]=deal('');
    group_count = 0;
    cell_count = 0;
    epoch_count = 0;
    
    epochs = struct('parameters',{},'data_link',{}, 'sample_rate',{},'start_time',{},'duration',{},'group', {},'block',{});
    for n = 1:NRetinas
      retinas(n).Name = rinfo(n).Attributes(2).Value;
      retinas(n).genotype = rinfo(n).Groups(2).Attributes(1).Value;
      retinas(n).eye = rinfo(n).Groups(2).Attributes(2).Value;
      retinas(n).orientation = rinfo(n).Groups(2).Attributes(3).Value;
      if length(rinfo(n).Groups(2).Attributes) > 3
          retinas(n).experimenter = rinfo(n).Groups(2).Attributes(4).Value;
      end
      
      cinfo = vertcat(...
        cell2mat(arrayfun(@(x) h5goto(hinfo, x.Value{1}),rinfo(n).Groups(4).Links, 'UniformOutput', false))',...
        rinfo(n).Groups(4).Groups...
        );
      
      %c1: rinfo(1).Groups(4).Links(1)
      %c2: rinfo(1).Groups(4).Groups(1)
      
      nCells = numel(cinfo);
      emp = cell(nCells, 1);
      retinas(n).cells = struct('Name', emp, 'online_label', emp, 'location', emp);

      for m = 1:nCells
          retinas(n).cells(m).Name = cinfo(m).Attributes(4).Value;
          properties = arrayfun( @(x) endsWith(x.Name,'properties'), cinfo(m).Groups);
          retinas(n).cells(m).online_label = cinfo(m).Groups(properties).Attributes(4).Value;
          retinas(n).cells(m).location = cinfo(m).Groups(properties).Attributes(3).Value;
          number = strcmp({cinfo(m).Groups(properties).Attributes(:).Name},'number');
          retinas(n).cells(m).name_full = sprintf('%d%s',cinfo(m).Groups(properties).Attributes(number).Value, retinas(n).Name);

          cell_count = cell_count + 1;
          for l = 1:numel(cinfo(m).Groups(1).Links)
              epochGroup = h5goto(hinfo, cinfo(m).Groups(1).Links(l).Value{1});
              uuid = epochGroup.Attributes(1).Value;
              if ~ismember(uuid,{epochGroups(:).uuid})
                  g = struct('uuid',uuid,'label',epochGroup.Attributes(4).Value,'retina',n,'cell',cell_count,'cell_label',retinas(n).cells(m).name_full);
                  %now we get to the epoch blocks:
                  nBlocks = numel(epochGroup.Groups(1).Groups);
                  emp = cell(nBlocks, 1);
                  g.blocks = struct('protocol',emp,'parameters',emp);
                  group_count = group_count + 1;
                  for k = 1:nBlocks
                      block = epochGroup.Groups(1).Groups(k);
                      protocol = split(block.Attributes(4).Value,'.');
                      g.blocks(k).protocol =  protocol{end};
                      g.blocks(k).parameters = struct('Name', {block.Groups(2).Attributes(:).Name}', 'Value',...
                          {block.Groups(2).Attributes(:).Value}', 'Type', arrayfun(@(x) x.Datatype.Class, block.Groups(2).Attributes, 'UniformOutput',false));
                      
                      %block.Groups(2).Attributes;
                      nEpochs = numel(block.Groups(1).Groups);
                      emp = cell(nEpochs, 1);
                      epochs = cat(1,epochs,struct('parameters',emp,'data_link',emp, 'sample_rate',emp,'start_time',emp,'duration',emp,'group',emp,'block',emp));
                      for j = 1:nEpochs
                          epoch_count = epoch_count + 1;
                          epoch = block.Groups(1).Groups(j);
                          epochs(epoch_count).parameters = struct('Name', {epoch.Groups(2).Attributes(:).Name}',...
                              'Value', {epoch.Groups(2).Attributes(:).Value}',...
                            'Type',arrayfun(@(x) x.Datatype.Class, epoch.Groups(2).Attributes, 'UniformOutput',false));
                          %epoch.Groups(2).Attributes;
                          epochs(epoch_count).data_link{1} = epoch.Groups(3).Groups(1).Name;
                          if numel(epoch.Groups(3).Groups) > 1
                            epochs(epoch_count).data_link{2} = epoch.Groups(3).Groups(2).Name;
                          end
                          epochs(epoch_count).sample_rate = epoch.Groups(3).Groups(1).Attributes(2).Value;
                          
                          start_time = strcmp({epoch.Attributes(:).Name}, 'startTimeDotNetDateTimeOffsetTicks');
                          time_zone = strcmp({epoch.Attributes(:).Name}, 'startTimeDotNetDateTimeOffsetOffsetHours');
                          
                          epochs(epoch_count).start_time = milliseconds(datetime(uint64(epoch.Attributes(start_time).Value),'convertfrom','.net','timezone',num2str(epoch.Attributes(time_zone).Value))-recording_date);
                          epochs(epoch_count).duration = (epoch.Attributes(4).Value - epoch.Attributes(2).Value)/1e4;
                          epochs(epoch_count).group = group_count;
                          epochs(epoch_count).block = k;
                          %epoch.Groups(3).Groups(1).sampleRate ...
                          %sampleRateUnits,
                          %inputTimeDotNetDateTimeOffsetTicks
                      end
                  
                  end
                  epochGroups(group_count) = g;
              else
                  warning('skipped an epoch group unexpectedly!');
              end
          end
      end
    end
    % epochs = cell2mat(arrayfun( @(x)cell2mat({x.blocks(:).epochs}'), epochGroups,'uniformoutput',false));
    [~,i] = sort([epochs(:).start_time]);
    epochs = epochs(i);

    function hinfo = h5goto(hinfo, dest)
      next = cellfun(@(x) contains(dest, x), {hinfo.Groups(:).Name});
      if strcmp(hinfo.Groups(next).Name, dest)
        hinfo = hinfo.Groups(next);
        return
      end
      hinfo = h5goto(hinfo.Groups(next), dest);
    end
  end

  function [keys, param_struct] = processCellData(~, cellData, epochs, epoch_groups)

    if cellData.savedDatasets.Count < 1
      return%we will not insert this cell
    end
    
    keys.datasets = struct('dataset_name', repmat(cellData.savedDataSets.keys()',1,2));
    keys.epochs = struct(); %TODO: fill in...

    v = cellData.savedDataSets.values();    
    for m = 1:cellData.savedDataSets.Count
      nEpochs = numel(v{m});
      % nChannels = numel(cellData.epochs(v{m}(1)).dataLinks.keys());
      % datasetEpochs = zeros(nEpochs,nChannels);
      
      % datasetChannels = zeros(1,nChannels);
      emp = cell(nEpochs,1);
      epochsDataset = struct('epoch_number', emp,'protocol_name', emp,'start_time',emp,'duration',emp);
      emp = cell(nEpochs, 2);
      c = repmat({1,2}, nEpochs, 1);
      channels = struct('epoch_number', emp, 'channel', c, 'amp_mode', emp, 'recording_mode', emp, 'amp_hold', emp, 'data_link', emp);
      
      datasetEpochs = struct(...
        'dataset_name',repmat({keys.datasets(m).dataset_name}, nEpochs, 2),...
        'epoch_number', emp,...
        'channel',c);
      
      for l = 1:nEpochs
        epoch = cellData.epochs(v{m}(l));
        channel1= epoch.dataLinks('Amplifier_Ch1');
        
        epoch_ind = find(strcmp(arrayfun(@(e) e.data_link{1}, epochs, 'uniformoutput',false), channel1(1:end-5)));
        epochsDataset(l).epoch_number = epoch_ind;
        [datasetEpochs(l,:).epoch_number] = deal(epoch_ind); %this key is done

        if ismember(epoch_ind, [keys.epochs(:).epoch_number])
          continue %we already parsed the epoch and channel data
        end
        
        %prepare the channel 1 key
        channels(l,1).data_link = channel1;
        channels(l,1).amp_hold = epoch.get('ampHoldSignal');
        if isnan(channels(l,1).amp_hold), channels(l,1).amp_hold = 0; end
        channels(l,1).recording_mode = ep.get('ampMode');
        if isnan(channels(l,1).recording_mode), channels(l,1).recording_mode = 'U'; end
        %TODO: what about this wholeCellRecordingMode_Ch1 business?
        channels(l,1).amp_mode = ep.get('amplifierMode');
        if isnan(channels(l,1).amp_mode), channels(l,1).amp_mode = 'U'; end


        %prepare the channel 2 key
        nChannels = length(epoch.dataLinks.keys());
        if nChannels== 2
          channels(l,2).data_link = epoch.dataLinks('Amplifier_Ch2');
          channels(l,2).amp_hold = epoch.get('amp2HoldSignal');
          if isnan(channels(l,2).amp_hold), channels(l,2).amp_hold = 0; end
          channels(l,2).recording_mode = ep.get('amp2Mode');
          if isnan(channels(l,2).recording_mode), channels(l,2).recording_mode = 'U'; end
          channels(l,2).amp_mode = ep.get('amplifier2Mode');
          if isnan(channels(l,2).amp_mode), channels(l,2).amp_mode = 'U'; end
        elseif nChannels > 2
          error('More than 2 channels in cell data file');
        end

        %prepare the epoch key
        % epochsDataset(l).protocol_name = epoch_groups(epochs(epoch_ind).group).blocks(epochs(epoch_ind).block).protocol;
        epochsDataset(l).start_time = epochs(epoch_ind).start_time;
        epochsDataset(l).duration = epochs(epoch_ind).duration;
        %TODO: params, spikes
        %the params will just become one big struct array... Name, Value, Type... n_params -by -nEpochs
        %since each epoch can have a different set of params... fill out with nan values
        %SymphonyProtocolSettings and SymphonyEpochSettings will take care of the rest
        % we will call those from makeTuples... they will return the settings ids
        %still need to work out projector settings though... will be similar but easier since all settings are fixed

        %for spikes:
        %  first check if there are spikes in channel 1 and channel 2 (if recording)
        %   if not, verify that it's not a spiking trial... otherwise we have an issue
      end

      %remove null epochs from epochsDataset, channels...
      %don't think we want this here %%%%flatten epochsDataset, channels, datasetEpochs and remove null channels

      %concatenate keys

      % keys.epochs = vertcat(keys.epochs, epochsDataset);
    end

  end
end
end