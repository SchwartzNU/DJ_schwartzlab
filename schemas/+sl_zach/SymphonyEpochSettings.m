%{
  # Group of settings used by an experiment
  settings_id: int unsigned auto_increment           # unique settings id TODO: seems like this isn't obeying transaction!!
  ---
  settings_count: tinyint unsigned                  #number of settings in this group
%}

classdef SymphonyEpochSettings < sl_zach.SymphonySettings & dj.Imported

properties (Constant, Access=private)
  bools = sl_zach.SymphonyEpochParameterBool().fetch('parameter_name');
  floats = sl_zach.SymphonyEpochParameterNumeric().fetch('parameter_name');
  strings = sl_zach.SymphonyEpochParameterString().fetch('parameter_name');
end

methods (Access = protected)
  function makeTuples(self, keys)
    error('Cannot insert Epoch Settings directly. Settings must be entered via the Symphony table');
  end
end

methods (Access = {?sl_zach.Symphony})
  function [indices, remainingKeys, inserted] = addParameterGroup(self, keys)
    % assume keys will be a struct of size M,N
    % M is the number of keys per epoch, and N is the number of epochs

    remainingKeys = ~ismember({keys(:,1).Name}, {vertcat(self.bools, self.floats, self.strings).parameter_name});
    keys(remainingKeys,:) = [];

    params_FLOAT = keys(strcmp({keys(:,1).Type},'H5T_FLOAT'),:);
    params_BOOL = keys(strcmp({keys(:,1).Type},'H5T_INTEGER'),:);
    params_STRING = keys(strcmp({keys(:,1).Type},'H5T_STRING'),:);

    bad = {params_BOOL(arrayfun(@(x) (x.Value~=1) && (x.Value~=0),params_BOOL(:))).Name};
    if numel(bad)
      error('Illegal value for boolean epoch parameters: %s\b\b. Must be 0 or 1. If value should not be bool, contact admin.', sprintf('%s, ', bad{:}));
    end
    
    %determine what needs to be added
    [~,u,d] = unique(cell2table(arrayfun(@(x) x.Value, keys, 'uniformoutput', false)'));
    indices = zeros(size(keys,2), 1);
    inserted = false(size(keys,2), 1);
    
    emp = cell(numel(u), 1);
    keys = struct('settings_id',emp, 'settings_count', repmat({size(keys,1)}, numel(u), 1));

    emp = cell(numel(u), size(params_FLOAT,1));
    keys_FLOAT = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);
    emp = cell(numel(u), size(params_BOOL,1));
    keys_BOOL = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);
    emp = cell(numel(u), size(params_STRING,1));
    keys_STRING = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);

    count = nan;
    for N = 1:length(u)
      %TODO: I don't think we really need the loop here... adds a lot of
      %if statements
      q = nan;
      c = join(arrayfun(@(x) sprintf('(parameter_name="%s" AND value=%f)', x.Name, x.Value), params_FLOAT(:,u(N)),'uniformoutput',false), ' OR ');
      if ~isempty(c{1})
        q = sl_zach.SymphonyEpochSettingsNumeric & c;
      end
      c = join(arrayfun(@(x) sprintf('(parameter_name="%s" AND value=%d)', x.Name, x.Value + 1), params_BOOL(:,u(N)),'uniformoutput',false), ' OR ');
      if ~isempty(c{1})
        if isnan(q)
          q = sl_zach.SymphonyEpochSettingsBool & c; 
        else
          q = q | (sl_zach.SymphonyEpochSettingsBool & c); 
        end
      end
      c = join(arrayfun(@(x) sprintf('(parameter_name="%s" AND value="%s")', x.Name, x.Value), params_STRING(:,u(N)),'uniformoutput',false), ' OR ');
      if ~isempty(c{1})
        if isnan(q)
          q = sl_zach.SymphonyEpochSettingsString & c; 
        else
          q = q | (sl_zach.SymphonyEpochSettingsString & c); 
        end
      end
      if isnan(q)
        error('No epoch settings specified!');
      end
      
      i = fetch(self.aggr(q, 'count(*)->n', 'settings_count') & "settings_count=n", 'settings_id');
      if isempty(i)
        if isnan(count)
          count = self.count() + 1;
          i = count;
        else
          count = count + 1;
          i = count;
        end
        keys(N).settings_id = i; %we are going to insert these
        [keys_FLOAT(N,:).settings_id] = deal(i);
        [keys_BOOL(N,:).settings_id] = deal(i);
        [keys_STRING(N,:).settings_id] = deal(i);

        [keys_FLOAT(N,:).parameter_name] = deal(params_FLOAT(:,u(N)).Name);
        [keys_FLOAT(N,:).value] = deal(params_FLOAT(:,u(N)).Value);
        [keys_BOOL(N,:).parameter_name] = deal(params_BOOL(:,u(N)).Name);
        
        isTrue = logical([params_BOOL(:,u(N)).Value]);
        [keys_BOOL(N,isTrue).value] = deal('true');
        [keys_BOOL(N,~isTrue).value] = deal('false');
        
        [keys_STRING(N,:).parameter_name] = deal(params_STRING(:,u(N)).Name);
        [keys_STRING(N,:).value] = deal(params_STRING(:,u(N)).Value);

        inserted(d==N) = true;
      else
        i = i.settings_id;
      end
      indices(d==N) = i; %we will return the settings_id for each input key
    end

    dups = arrayfun(@(x) isempty(x.settings_id), keys);
    keys(dups) = [];
    keys_FLOAT(dups,:) = [];
    keys_BOOL(dups,:) = [];
    keys_STRING(dups,:) = [];

    self.insert(keys);
    sl_zach.SymphonyEpochSettingsNumeric().insert(keys_FLOAT(:));
    sl_zach.SymphonyEpochSettingsBool().insert(keys_BOOL(:));
    sl_zach.SymphonyEpochSettingsString().insert(keys_STRING(:));

  end
end

  methods %TODO: remove this
    function fake(self)
      C = dj.conn();
      C.startTransaction;
      try
        self.insert({1});
        sl_zach.SymphonyEpochSettingsNumeric().insert({1, 'curSpotSize', 1200});
        C.commitTransaction;
      catch
        C.cancelTransaction;
      end
    end
  end

end