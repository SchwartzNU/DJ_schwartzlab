%{ NOT a datajoint table

%}
classdef ExperimentPart < dj.Part
properties(Access={?sln_symphony.Experiment,...
  ?sln_symphony.ExperimentProtocols,...
  ?sln_symphony.Calibration,...
  ?sln_symphony.Dataset})
  canInsert = false;
end
methods
  function ret = insert(self,key)
    if self.canInsert
      insert@dj.Part(self,key);
      ret = true;
    else
      error('You cannot insert into this table directly.');
    end
  end
end
end