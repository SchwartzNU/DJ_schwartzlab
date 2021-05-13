%{
# The retina for each cell, if applicable
-> sl_zach.Cell
---
-> sl.Eye             # which eye
%}

classdef CellRetina < dj.Part
properties(SetAccess=protected)
  master = sl_zach.Cell;
end
end
