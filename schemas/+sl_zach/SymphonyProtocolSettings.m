%{
  # Group of settings used by an experiment
  settings_id: int unsigned auto_increment           # unique settings id TODO: seems like this isn't obeying transaction!!
  ---
  settings_count: tinyint unsigned                  #number of settings in this group
%}

classdef SymphonyProtocolSettings < sl_zach.SymphonySettings & dj.Imported

properties (Constant, Access=private)
  %TODO: wrap these in another class so that they can be updated...
  % see MATLAB docs > Static Data > Static data object
  % idea is that one would call SymphonyProtocolParameter_().insert(...)
  % and then SymphonyProtocolSettings.updateParameters()
  % which would in turn call
  % SymphonyProtocolSettings.sharedDataObject.update()
  % similarly, access via self.sharedDataObject.strings
  
  %NOTE: these are constant so that we don't constantly query for the
  %parameters. see above todo to improve this model.
  bools = sl_zach.SymphonyProtocolParameterBool().fetch('parameter_name');
  floats = sl_zach.SymphonyProtocolParameterNumeric().fetch('parameter_name');
  strings = sl_zach.SymphonyProtocolParameterString().fetch('parameter_name');
  blobs = sl_zach.SymphonyProtocolParameterBlob().fetch('parameter_name');
  exclude = sl_zach.SymphonyParameterExclude().fetch();
end

methods (Access = protected)
  function makeTuples(self, keys)
    error('Cannot insert Protocol Settings directly. Settings must be entered via the Symphony table');
  end
end

methods (Access = {?sl_zach.Symphony})
  function [indices, remainingKeys, inserted] = addParameterGroup(self, values, names, unhashed)
    % assume values are a cell array of size M,N containing strings or
    % numbers
    
    % M is the number of parameter keys, and N is the number of epochs

    remainingKeys = ~ismember(names, vertcat({self.bools(:).parameter_name}', {self.floats(:).parameter_name}', {self.strings(:).parameter_name}', {self.blobs(:).parameter_name}'));
    remainingKeys = remainingKeys | ismember(names, {self.exclude(:).parameter_name}');

    values(remainingKeys,:) = [];
    names(remainingKeys) = [];
    unhashed(remainingKeys,:) = [];
    
    is_FLOAT = ismember(names, {self.floats(:).parameter_name});
    is_BOOL = ismember(names, {self.bools(:).parameter_name});
    is_STRING = ismember(names, {self.strings(:).parameter_name});
    is_BLOB = ismember(names, {self.blobs(:).parameter_name});
    
    bad = names(is_BOOL(any(cellfun(@(x) (x ~= 0) && (x ~= 1) && ~isnan(x), values(is_BOOL, :)),2)));
    if numel(bad)
      error('Illegal value for boolean protocol parameters: %s\b\b. Must be 0 or 1. If value should not be bool, contact admin.', sprintf('%s, ', bad{:}));
    end
    
    %determine what needs to be added
    tv = values;
    tv(~is_STRING,:) = cellfun(@(x) typecast(double(x), 'uint64'), tv(~is_STRING,:),'uniformoutput',false);
    tv(cellfun(@(x) length(x)==1 && isnan(x),tv)) = {''}; 
    [~,u,d] = unique(cell2table(tv'));
    %NOTE: this is a hacky way to get unique to work
    % 1) first, we convert all numbers to doubles. this just guarantees that
    % each value has the same number of bits.
    %
    % 2) next, since unique doesn't operate as desired for nans, we
    % 'typecast' to uint64. This just changes how matlab interprets the
    % numbers, but they still have the same underlying binary data, so
    % unique is valid. NaN is not defined for uint64: it's treated as a
    % normal number. this is what we want, i.e., for all nans to be treated
    % as the same number.
    %
    % 3) finally, we convert to a table. matlab doesn't allow
    % unique({},'rows'), since it doesn't know how to determine if two cell
    % arrays are unique (since they can hold anything). by converting to a
    % table, we are implicitly "flattening" the cell array. each column in
    % a table must have the same datatype, whereas this is not the case for
    % a cell array (by comparison, each element in a matrix must have the
    % same datatype). under the hood, when cell2table is called matlab
    % converts each numeric column to a standard vector and each string
    % column to a 1D cell array of strings. unique is easily defineable and
    % in fact defined for such a table. note that if the cell array were
    % not flattenable, e.g. values{1,1} == {'stringA','stringB'}, this
    % would not work.
    
    indices = zeros(size(values,2), 1);
    inserted = false(size(values,2), 1);
    
    emp = cell(numel(u), 1);
    keys = struct('settings_id',emp, 'settings_count', emp);
    %TODO: filter nans: instead of settings_count = size(keys,1), should be number of non-nans for each N in u 

    emp = cell(0, 1);
    keys_FLOAT = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);
    %emp = cell(numel(u), nnz(is_FLOAT));
    keys_BOOL = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);
    %emp = cell(numel(u), nnz(is_STRING));
    keys_STRING = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);
    %emp = cell(numel(u), nnz(is_BLOB));
    keys_BLOB = struct('settings_id', emp, 'parameter_name',emp, 'value', emp, 'hash', emp);

    count = nan;
    for N = 1:length(u)
      %TODO: I don't think we really need the loop here... adds a lot of
      %if statements
      keep = cellfun(@(x) length(x)>1 || ~isnan(x), values(:,u(N)));
%       value = values(~ignore,u(N));
%       name = names(~ignore);
      keys(N).settings_count = nnz(keep);
      
      q = nan;
      
      float_i = keep & is_FLOAT;
      c = join(cellfun(@(x,y) sprintf('(parameter_name="%s" AND value=%f)',x,y), names(float_i), values(float_i, u(N)) ,'uniformoutput',false), ' OR ');
      %TODO: filter nans for c... params_FLOAT(~isnan(params_FLOAT(:,u(N)))) ... or similar
      if ~isempty(c{1})
        q = sl_zach.SymphonyProtocolSettingsNumeric & c;
      end
      
      bool_i = keep & is_BOOL;
      c = join(cellfun(@(x,y) sprintf('(parameter_name="%s" AND value=%d)', x, y + 1), names(bool_i), values(bool_i, u(N)),'uniformoutput',false), ' OR ');
      if ~isempty(c{1})
        if isnan(q)
          q = sl_zach.SymphonyProtocolSettingsBool & c; 
        else
          q = q | (sl_zach.SymphonyProtocolSettingsBool & c); 
        end
      end
      
      string_i = keep & is_STRING;
      c = join(cellfun(@(x,y) sprintf('(parameter_name="%s" AND value="%s")', x,y), names(string_i), values(string_i,u(N)),'uniformoutput',false), ' OR ');
      if ~isempty(c{1})
        if isnan(q)
          q = sl_zach.SymphonyProtocolSettingsString & c; 
        else
          q = q | (sl_zach.SymphonyProtocolSettingsString & c); 
        end
      end
      
      blob_i = keep & is_BLOB;
%       hashes = do_hash(values(blob_i,u(N)), names(blob_i));
      c = join(cellfun(@(x,y) sprintf('(parameter_name="%s" AND hash="%d")', x,y), names(blob_i), values(blob_i, u(N)),'uniformoutput',false), ' OR ');
      if ~isempty(c{1})
        if isnan(q)
          q = sl_zach.SymphonyProtocolSettingsBlob & c; 
        else
          q = q | (sl_zach.SymphonyProtocolSettingsBlob & c); 
        end
      end
      
      if isnan(q)
        error('No protocol settings specified!');
      end
      
      i = fetch(self.aggr(q, 'count(*)->n', 'settings_count') & "settings_count=n", 'settings_id');
      %TODO: 
      if isempty(i)
        if isnan(count)
          % count = fetch1(self, 'max(settings_id)+1 -> next');
          count = self.count + 1; %TODO: debug this
          i = count;
        else
          count = count + 1;
          i = count;
        end
        keys(N).settings_id = i; %we are going to insert these
        
        emp = cell(nnz(float_i), 1);
        temp_FLOAT = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);
        emp = cell(nnz(bool_i), 1);
        temp_BOOL = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);
        emp = cell(nnz(string_i), 1);
        temp_STRING = struct('settings_id', emp, 'parameter_name',emp, 'value', emp);
        emp = cell(nnz(blob_i), 1);
        temp_BLOB = struct('settings_id', emp, 'parameter_name',emp, 'value', emp, 'hash', emp);
        
        [temp_FLOAT(:).settings_id] = deal(i);
        [temp_BOOL(:).settings_id] = deal(i);
        [temp_STRING(:).settings_id] = deal(i);
        [temp_BLOB(:).settings_id] = deal(i);

        [temp_FLOAT(:).parameter_name] = deal(names{float_i});
        [temp_FLOAT(:).value] = deal(values{float_i, u(N)});
        
        [temp_BOOL(:).parameter_name] = deal(names{bool_i});
        isTrue = cellfun(@logical, values(bool_i, u(N)));
        [temp_BOOL(isTrue).value] = deal('true');
        [temp_BOOL(~isTrue).value] = deal('false');
        
        [temp_STRING(:).parameter_name] = deal(names{string_i});
        [temp_STRING(:).value] = deal(values{string_i, u(N)});
        
        [temp_BLOB(:).parameter_name] = deal(names{blob_i});
        [temp_BLOB(:).hash] = deal(values{blob_i, u(N)});
        [temp_BLOB(:).value] = deal(unhashed{blob_i, u(N)});
        
        keys_FLOAT = vertcat(keys_FLOAT, temp_FLOAT);
        keys_BOOL = vertcat(keys_BOOL, temp_BOOL);
        keys_STRING = vertcat(keys_STRING, temp_STRING);
        keys_BLOB = vertcat(keys_BLOB, temp_BLOB);
        
        inserted(d==N) = true;
      else
        i = i.settings_id;
      end
      indices(d==N) = i; %we will return the settings_id for each input key
    end

    dups = arrayfun(@(x) isempty(x.settings_id), keys);
    keys(dups) = [];
%     keys_FLOAT(dups,:) = [];
%     keys_BOOL(dups,:) = [];
%     keys_STRING(dups,:) = [];

    %TODO: filter nans:
    %keys_FLOAT = keys_FLOAT(isnan(keys_FLOAT(:).Value)) or similar

    self.insert(keys);
    sl_zach.SymphonyProtocolSettingsNumeric().insert(keys_FLOAT);
    sl_zach.SymphonyProtocolSettingsBool().insert(keys_BOOL);
    sl_zach.SymphonyProtocolSettingsString().insert(keys_STRING);
    sl_zach.SymphonyProtocolSettingsBlob().insert(keys_BLOB);
    
  end
end

methods

  %TODO: remove this
  function fake(self)
    C = dj.conn();
    C.startTransaction;
    try
      self.insert({1,13});
      sl_zach.SymphonyProtocolSettingsNumeric().insert({
        1, 'maxSize', 1200;
        1, 'minSize', 30;
        1, 'meanLevel', 0;
        1, 'numberOfCycles',2;
        1, 'numberOfPatterns', 1;
        1, 'numberOfSizeSteps', 12;
        1, 'preTime', 500;
        1, 'stimTime', 1000;
        1, 'tailTime', 1000;
        1, 'symphonyVersion', 2;
        1, 'protocolVersion', 2;
        });
      sl_zach.SymphonyProtocolSettingsBool().insert({
        1,'logScaling','true';
        1,'randomOrdering','true';
        });
      C.commitTransaction;
    catch
      C.cancelTransaction;
    end
  end
end
end