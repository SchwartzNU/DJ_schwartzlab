%{
  # Settings for a Stage Protocol
  settings_id: int unsigned auto_increment           # unique settings id
  ---
  rstar_foreground : float
  rstar_foreground2 = 0 : float
  rstar_background : float

  mstar_foreground : float
  mstar_foreground2 = 0 : float
  #mstar_background : float

  sstar_foreground : float
  sstar_foreground2 = 0 : float
  #sstar_background : float

  red_led: tinyint unsigned      # assumes bitDepth == 8
  green_led : tinyint unsigned
  blue_led : tinyint unsigned

  ndf : tinyint unsigned
  
  frame_rate : float
  foreground_intensity : decimal(3,2)  # a decimal from 0.00 to 1.00, fraction of time foreground is illuminated
  background_intensity : decimal(3,2)  # a decimal from 0.00 to 1.00, fraction of time background is illuminated

  foreground_intensity2 = 0 : decimal(3,2)
  background_intensity2 = 0 : decimal(3,2) 

  contrast1 = 1 : decimal(3,2)
  contrast2 = 1 : decimal(3,2)

  color_combination_mode = 'none' : enum('contrast', 'add', 'replace', 'none')
  foreground_pattern = 'A' : enum('A','B')
  background_pattern = 'A' : enum('A', 'B')

  prerender : enum('on', 'off')
  force_prerender : enum('auto', 'on', 'off')

  microns_per_pixel : float
  angle_offset : float
  offset_x : float
  offset_y : float

  scanhead_trigger = 'off' : enum('on', 'off')

%}

classdef SymphonyProjectorSettings < dj.Imported
methods (Access = protected)
  function makeTuples(self, keys)
    error('Cannot insert Projector Settings directly. Settings must be entered via the Symphony table');
  end
end

methods (Access = {?sl_zach.Symphony})
  function [indices, remainingKeys, inserted] = addParameterGroup(self, values, names)

    ss = substruct('{}',{':'});
    emp = repmat({nan}, size(values,2), 1);%cell(size(values,2), 1);
    keys = struct(...
    'rstar_foreground',emp,'mstar_foreground',emp,'sstar_foreground',emp,...
    'rstar_foreground2',emp,'mstar_foreground2',emp,'sstar_foreground2',emp,...
    'rstar_background',emp,...%'mstar_background',emp,'sstar_background',emp,...
    'red_led',emp,'green_led',emp,'blue_led',emp,...
    'ndf', emp, 'frame_rate', emp, 'foreground_intensity',emp, 'foreground_intensity2', emp, 'background_intensity', emp, 'background_intensity2', emp,...
    'contrast1', emp, 'contrast2', emp,...
    'color_combination_mode', emp, 'foreground_pattern', emp, 'background_pattern', emp,...
    'prerender',emp, 'force_prerender', emp,...
    'microns_per_pixel',emp,'angle_offset',emp,'scanhead_trigger', emp,...
    'offset_x', emp, 'offset_y', emp,...
    'settings_id',emp...
    );

    if any(strcmp(names,'RstarIntensity'))
        [keys(:).rstar_foreground] = subsref(values(strcmp(names,'RstarIntensity'),:), ss);
        [keys(:).mstar_foreground] = subsref(values(strcmp(names,'MstarIntensity'),:), ss);
        [keys(:).sstar_foreground] = subsref(values(strcmp(names,'SstarIntensity'),:), ss);
    else
        [keys(:).rstar_foreground] = subsref(values(strcmp(names,'RstarIntensity1'),:), ss);
        [keys(:).mstar_foreground] = subsref(values(strcmp(names,'MstarIntensity1'),:), ss);
        [keys(:).sstar_foreground] = subsref(values(strcmp(names,'SstarIntensity1'),:), ss);
    end
    
    if any(strcmp(names,'RstarIntensity2'))
        [keys(:).rstar_foreground2] = subsref(values(strcmp(names,'RstarIntensity2'),:), ss);
        [keys(:).mstar_foreground2] = subsref(values(strcmp(names,'MstarIntensity2'),:), ss);
        [keys(:).sstar_foreground2] = subsref(values(strcmp(names,'SstarIntensity2'),:), ss);
    else
        [keys(:).rstar_foreground2] = deal(0);
        [keys(:).mstar_foreground2] = deal(0);
        [keys(:).sstar_foreground2] = deal(0);
    end

    [keys(:).rstar_background] = subsref(values(strcmp(names,'RstarMean'),:), ss);
%     [keys(:).mstar_background] = subsref(values(strcmp(names,'MstarMean'),:), ss);
%     [keys(:).sstar_background] = subsref(values(strcmp(names,'SstarMean'),:), ss);

    color_patterns = values(strcmp(names,'colorPattern1') | strcmp(names,'colorPattern2') | strcmp(names,'colorPattern3'), :);

    keys_ind = 1:numel(keys);
    red_ind = strcmp(names,'redLED') | strcmp(names, 'uvLED');
    green_ind = strcmp(names, 'greenLED');
    blue_ind = strcmp(names,'blueLED');

    [keys(:).red_led] = subsref(arrayfun(@(x) values{red_ind,x}.*any(contains(color_patterns(:,x), 'red') | contains(color_patterns(:,x), 'uv')) ,keys_ind,'uniformoutput', false), ss);
    [keys(:).green_led] = subsref(arrayfun(@(x) values{green_ind,x}.*any(contains(color_patterns(:,x), 'green')) ,keys_ind,'uniformoutput', false), ss);
    [keys(:).blue_led] = subsref(arrayfun(@(x) values{blue_ind,x}.*any(contains(color_patterns(:,x), 'blue')) ,keys_ind,'uniformoutput', false), ss);

    if any(strcmp(names, 'colorCombinationMode'))
        contrastMode = cellfun(@(x) strcmp(x,'contrast'), values(strcmp(names, 'colorCombinationMode'), :));
        addMode = cellfun(@(x) strcmp(x,'add'), values(strcmp(names, 'colorCombinationMode'), :));
        replaceMode = cellfun(@(x) strcmp(x,'replace'), values(strcmp(names, 'colorCombinationMode'), :));
        [keys(contrast_mode).color_combination_mode] = deal('contrast');
        [keys(add_mode).color_combination_mode] = deal('add');
        [keys(replace_mode).color_combination_mode] = deal('replace');
    else
        [keys(:).color_combination_mode] = deal('none');
    end

    if any(strcmp(names,'primaryObjectPattern'))
        foregroundA = cellfun(@(x) x==1, values(strcmp(names, 'primaryObjectPattern'), :));
        foregroundB = cellfun(@(x) x==2, values(strcmp(names, 'primaryObjectPattern'), :));
        [keys(foregroundA).foreground_pattern] = deal('A');
        [keys(foregroundB).foreground_pattern] = deal('B');
    else
        [keys(:).foreground_pattern] = deal('A');
    end
    
    if any(strcmp(names,'backgroundPattern'))
        backgroundA = cellfun(@(x) x==1, values(strcmp(names, 'backgroundPattern'), :));
        backgroundB = cellfun(@(x) x==2, values(strcmp(names, 'backgroundPattern'), :));
        [keys(backgroundA).background_pattern] = deal('A');
        [keys(backgroundB).background_pattern] = deal('B');
    else
        [keys(:).background_pattern] = deal('A');
    end

    [keys(:).ndf] = subsref(values(strcmp(names, 'NDF'), :), ss);

    [keys(:).frame_rate] = subsref(values(strcmp(names, 'frameRate'), :), ss);
    
    if any(strcmp(names,'intensity') | strcmp(names,'intensity1'))
        [keys(:).foreground_intensity] = subsref(values(strcmp(names, 'intensity') | strcmp(names, 'intensity1'), :), ss);
        [keys(isnan([keys(:).foreground_intensity])).foreground_intensity] = deal(1);
    else
        [keys(:).foreground_intensity] = deal(1); %NOTE: this seems to be an issue for SplitField
    end
    [keys(:).background_intensity] = subsref(values(strcmp(names, 'meanLevel') | strcmp(names, 'meanLevel1'), :), ss);
    
    if any(strcmp(names,'intensity2'))
        [keys(:).foreground_intensity2] = subsref(values(strcmp(names, 'intensity2'), :), ss);
    else
        [keys(:).foreground_intensity2] = deal(0);
    end
    if any(strcmp(names,'meanLevel2'))
        [keys(:).background_intensity2] = subsref(values(strcmp(names, 'meanLevel2'), :), ss);
    else
        [keys(:).background_intensity2] = deal(0);
    end

    if any(strcmp(names,'contrast1'))
        [keys(:).contrast1] = subsref(values(strcmp(names, 'contrast1'), :), ss);
    else
        [keys(:).contrast1] = deal(1);
    end
    
    if any(strcmp(names, 'contrast2'))
        [keys(:).contrast2] = subsref(values(strcmp(names, 'contrast2'), :), ss);
    else
        [keys(:).contrast2] = deal(1);
    end

    if any(strcmp(names, 'scanHeadTrigger'))
      isTriggered =cellfun(@(x) x==1, values(strcmp(names, 'scanHeadTrigger'), :));
      [keys(isTriggered).scanhead_trigger] = deal('on');
      [keys(~isTriggered).scanhead_trigger] = deal('off');
    else
      [keys(:).scanhead_trigger] = deal('off');
    end
    
    prerender = cellfun(@logical, values(strcmp(names, 'prerender'), :));
    autoForcePrerender = cellfun(@(x) strcmp(x,'auto'), values(strcmp(names, 'forcePrerender'), :));
    dontForcePrerender = cellfun(@(x) strcmp(x,'pr off') || strcmp(x,'prerender off'), values(strcmp(names, 'forcePrerender'), :));
    doForcePrerender = cellfun(@(x) strcmp(x,'pr on') || strcmp(x,'prerender on'), values(strcmp(names, 'forcePrerender'), :));

    [keys(prerender).prerender] = deal('on');
    [keys(~prerender).prerender] = deal('off');
    
    [keys(autoForcePrerender).force_prerender] = deal('auto');
    [keys(dontForcePrerender).force_prerender] = deal('off');
    [keys(doForcePrerender).force_prerender] = deal('on');

    [keys(:).microns_per_pixel] = subsref(values(strcmp(names, 'micronsPerPixel'), :), ss);
    [keys(:).angle_offset] = subsref(values(strcmp(names, 'angleOffsetFromRig'), :), ss);

    [keys(:).offset_x] = subsref(values(strcmp(names, 'offsetX'), :), ss);
    [keys(:).offset_y] = subsref(values(strcmp(names, 'offsetY'), :), ss);
    
    
    [keys(:).settings_id] = deal(0);
    
    remainingKeys = ~ismember(names,{
        'RstarIntensity', 'MstarIntensity','SstarIntensity',...
        'RstarIntensity1', 'MstarIntensity1','SstarIntensity1',...
        'RstarIntensity2', 'MstarIntensity2','SstarIntensity2',...
        'RstarMean','MstarMean','SstarMean',... %seems we only track rstar mean?
        'redLED','greenLED','blueLED','uvLED',...
        'NDF','frameRate',...
        'intensity','meanLevel','intensity1','intensity2','meanLevel1','meanLevel2','contrast1','contrast2',...
        'colorPattern1', 'colorPattern2','colorPattern3', 'numberOfPatterns','colorCombinationMode'... %these are handled implicitly
        'primaryObjectPattern','secondaryObjectPattern','backgroundPattern',... %secondary pattern is presumed useless
        'prerender','forcePrerender','micronsPerPixel','angleOffsetFromRig','scanHeadTrigger',...
        'offsetX','offsetY',...
        'bitDepth',... %bitDepth is always assumed 8
        });

    [~,u,d] = unique(struct2table(keys'));
    indices = zeros(size(values,2), 1);
    inserted = false(size(values,2), 1);

    count = nan;
    for N = 1:length(u)
      i = fetch(self & rmfield(keys(u(N)),'settings_id'), 'settings_id');

      if isempty(i)
        if isnan(count)
          % count = fetch1(self, 'max(settings_id)+1 -> next');
          count = self.count + 1; %TODO: debug this
          i = count;
        else
          count = count + 1;
          i = count;
        end
        keys(u(N)).settings_id = i; %we are going to insert these        
        inserted(d==N) = true;
      else
        i = i.settings_id;
      end
      indices(d==N) = i; %we will return the settings_id for each input key
    end
    keys = keys(logical([keys(:).settings_id]));
    self.insert(keys);

  end
end
end