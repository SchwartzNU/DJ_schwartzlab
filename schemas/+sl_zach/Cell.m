%{
# A real cell
cell_unid: int unsigned auto_increment
---
-> sl.Animal
%}
classdef Cell < dj.Imported
methods (Access = protected)
  function makeTuples(self, keys)
    error('Cannot insert Protocol Settings directly. Settings must be entered via the Symphony table');
  end
end
end