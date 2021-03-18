%{
  # Group of settings used by an epoch
  settings_id: int unsigned auto_increment           # unique settings id
%}

classdef SymphonyEpochSettings < dj.Imported

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
    function [indices, remainingKeys] = addParameterGroup(self, keys)
      % assume keys will be a struct of size M,N
      % M is the number of keys per epoch, and N is the number of epochs

      params_FLOAT = keys(strcmp({keys(:,1).Type},'H5T_FLOAT'),:);
      params_BOOL = keys(strcmp({keys(:,1).Type},'H5T_INTEGER'),:);
      params_STRING = keys(strcmp({keys(:,1).Type},'H5T_STRING'),:);
      
      bad = {params_FLOAT(~ismember({params_FLOAT(:,1).Name}, self.floats),1).Name};
      if numel(bad)
        error('Numeric epoch parameters missing from database: %s\b\b. If problem persists after adding, try restarting MATLAB.', sprintf('%s, ', bad{:}));
      end
      bad = {params_BOOL(~ismember({params_BOOL(:,1).Name}, self.bools),1).Name};
      if numel(bad)
        error('Boolean epoch parameters missing from database: %s\b\b. If problem persists after adding, try restarting MATLAB.', sprintf('%s, ', bad{:}));
      end
      bad = {params_BOOL(arrayfun(@(x) (x.Value~=1) && (x.Value~=0),params_BOOL(:))).Name};
      if numel(bad)
        error('Illegal value for boolean epoch parameters: %s\b\b. Must be 0 or 1. If value should not be bool, contact admin.', sprintf('%s, ', bad{:}));
      end
      bad = {params_STRING(~ismember({params_STRING(:,1).Name}, self.strings),1).Name};
      if numel(bad)
        error('String epoch parameters missing from database: %s\b\b. If problem persists after adding, try restarting MATLAB.', sprintf('%s, ', bad{:}));
      end
      
      %at this point we can add if needed

    end
  end

  methods 
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