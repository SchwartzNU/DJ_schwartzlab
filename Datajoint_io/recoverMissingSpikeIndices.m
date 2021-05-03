function [signal, spike_inds,merged,spike_counts] = recoverMissingSpikeIndices(f)
  CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
  RAW_DATA_FOLDER = getenv('RAW_DATA_FOLDER');
  RAW_DATA_MASTER = getenv('RAW_DATA_MASTER');
  ANALYSIS_CODE_FOLDER = getenv('ANALYSIS_CODE_FOLDER');
  
  if nargin<1
      q = sl.Epoch * (proj((...
          sl.Epoch & "recording_mode='Cell attached' OR recording2_mode='Cell attached'")...
          * sl_mutable.RecordingChannels)...
          & "(recording_mode='Cell attached' AND channel=1 AND data_link IS NOT NULL) OR (recording2_mode='Cell attached' AND channel=2 AND data_link2 IS NOT NULL)")...
          - sl_mutable.SpikeTrain;

      f = fetch(q, 'protocol_params', 'data_link', 'data_link2','raw_data_filename');
  end
  [cdn,~,cd_index] = unique({f(:).cell_data}');
  epoch_number = [f(:).epoch_number]';
  channel_number = [f(:).channel]';
  merged = false(numel(f),1);
  spike_counts = zeros(numel(f),1);
  links = {f(:).data_link; f(:).data_link2}';
  raw = {f(:).raw_data_filename}';
  cell_id = {f(:).cell_id}';
  
  signal = cell(numel(f),1);
  spike_inds = cell(numel(f), 1);

  global spikeFilter;
  spikefilter = load(sprintf('%sutilities/spikeFilter.mat', ANALYSIS_CODE_FOLDER),'spikeFilter');
  spikeFilter = spikefilter.spikeFilter;

  for n=1:numel(cdn)
    load(sprintf('%s%s', CELL_DATA_FOLDER, cdn{n}),'cellData');
    ind = cd_index==n;
    epochs = epoch_number(ind);
    channel = channel_number(ind);
    dl = links(ind,:);
    rdf = raw(ind,:);
    mrg = false(numel(epochs),1);
    sp_cnt = zeros(numel(epochs),1);
    cid = cell_id(ind);
    
    sig = cell(numel(epochs),1);
    si = cell(numel(epochs),1);

    for m = 1:numel(epochs)
      epoch = epochs(m);
      thresh = cellData.epochs(epoch).get('spikeThreshold');
      mode = cellData.epochs(epoch).get('spikeDetectorMode');
      if strcmp(mode,'Filtered Threshold')
        mode = 'advanced';
      elseif any(isnan(mode)) || strcmp(mode,'none')
          mode = 'Simple Threshold';
      end
      
      
      if ~isnan(thresh) && (strcmp(mode,'advanced') || strcmp(mode,'Simple threshold') || strcmp(mode,'Simple Threshold')) 
        fname = sprintf('%s%s.h5', RAW_DATA_FOLDER, rdf{m});

        if ~exist(fname, 'file')
          fprintf('Downloading raw data for %s\n', rdf{m});
          copyfile(sprintf('%s%s.h5', RAW_DATA_MASTER, rdf{m}), fname);
          if ~exist(fname,'file')
              warning('Could not find raw data!');
              continue
          end
        end
        
%         if isempty(dl{m, channel(m)})
%             mrg(m) = true;
%             sp_cnt(m) = nan;
%             continue
%         end
        
        try
            h5 = h5read(fname, dl{m, channel(m)});
        catch me
            warning('Error reading h5 file %s.', rdf{m});
            disp(getReport(me, 'extended', 'hyperlinks', 'on'));
            continue
        end
        sig{m} = h5.quantity;
        si{m} = detectSpikes(h5.quantity, thresh, cellData.epochs(epoch).get('sampleRate'), strcmp(mode,'advanced'));
        cellData.epochs(epoch).attributes(sprintf('spikes_ch%d', channel(m))) = si{m};
        mrg(m) = true;
        sp_cnt(m) = numel(si{m});

      else
        warning('Unable to update cell %s, epoch %d, mode = %s, thresh= %d', cid{m}, epoch, mode, thresh);
      end
    end
    merged(ind) = mrg;
    spike_counts(ind) = sp_cnt;
    signal(ind) = sig;
    spike_inds(ind) = si;
    if any(mrg)
      save(sprintf('%s%s', CELL_DATA_FOLDER, cdn{n}),'cellData');
    end
    
  end

end


function [fdata, noise] = filterResponse(fdata)
  global spikeFilter;
  if isempty(fdata)
      noise = [];
      return
  end
  fdata = [fdata(1) + zeros(1,2000), fdata, fdata(end) + zeros(1,2000)];
  fdata = filtfilt(spikeFilter, fdata);
  fdata = fdata(2001:(end-2000));
  noise = median(abs(fdata) / 0.6745);
end



function spikeIndices = detectSpikes(resp,threshold,sampleRate, doFilter)
  
  response = resp' - mean(resp);
     
      % get detection config
      % ind = get(obj.handles.detectorModeMenu, 'value');
      % s = get(obj.handles.detectorModeMenu, 'String');
      % obj.mode = s{ind};
      % obj.threshold = str2double(get(obj.handles.thresholdEdit, 'String'));
      
  if doFilter
      [fresponse, noise] = filterResponse(response);
      spikeIndices = getThresCross(fresponse, noise * threshold, sign(threshold));
  else
      spikeIndices = getThresCross(response, threshold, sign(threshold));
  end
          
  % refine spike locations to tips
  if threshold < 0
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
      
  %remove double-counted spikes
  if length(spikeIndices) >= 2
      ISItest = diff(spikeIndices);
      spikeIndices = spikeIndices([(ISItest > (0.001 * sampleRate)) true]);
  end

end