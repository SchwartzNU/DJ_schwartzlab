%{ NOT a datajoint table
%}
classdef ExperimentProtocol < dj.Part
  properties(SetAccess=protected)
    master = sln_symphony.Experiment;
  end
  properties(Abstract)
    renamed_attributes
    dropped_attributes
  end
  methods(Abstract)
    add_attributes(self, block_key, epoch_key)
  end

  methods
    function insert(self, block_key, epoch_key)
      is_epoch = contains(class(self), 'Epoch');
      key = self.add_attributes(block_key, epoch_key);
      if isempty(key)
        if is_epoch
          key = epoch_key;
        else
          key = block_key;
        end
      end
      fields = fieldnames(key);
      key = struct2cell(key);
      to_drop = ismember(fields, self.dropped_attributes);
      fields(to_drop) = [];
      key(to_drop,:) = [];
      
      % if is_epoch
      %   to_xfer = ismember(fields, self.transferred_attributes);
      %   fields(to_xfer) = [];
      %   key(to_xfer,:) = [];
      % else
      %   fields_e = fieldnames(epoch_key);
      %   key_e = struct2cell(epoch_key);
      %   to_xfer = ismember(fields_e, self.transferred_attributes);
      %   key = cat(1,key,key_e(to_xfer,:));
      %   fields = cat(1,fields,fields_e(to_xfer));
      % end

      renamed_f = fieldnames(self.renamed_attributes);
      [f,field_i] = intersect(fields, renamed_f);
      for i = 1:numel(field_i)
          fields{field_i(i)} = self.renamed_attributes.(f{i});
      end

      key = cell2struct(key, fields, 1);
      insert@dj.Part(self, key);
    end
    
    function [success,extra,missing] = canInsert(self, block_key, epoch_key)
      is_epoch = contains(class(self), 'Epoch');
      
      key = self.add_attributes(block_key, epoch_key);
      if isempty(key)
        if is_epoch
          key = epoch_key;
        else
          key = block_key;
        end
      end
      fields = fieldnames(key);
      fields = setdiff(fields, self.dropped_attributes);

      % if is_epoch
      %   fields = setdiff(fields, self.transferred_attributes);
      % else
      %   fields = vertcat(fields, self.transferred_attributes);
      % end

      renamed_f = fieldnames(self.renamed_attributes);
      [f,field_i] = intersect(fields, renamed_f);
      for i = 1:numel(field_i)
          fields{field_i(i)} = self.renamed_attributes.(f{i});
      end
      
      extra = setdiff(fields, self.tableHeader.names);
      missing = setdiff(self.tableHeader.names, fields);
      if isempty(extra) && isempty(missing)
        success = true;
      else
        success = false;
      end
    end
  end

end