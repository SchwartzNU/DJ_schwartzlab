%{
# CellAnalyzed table stores cells for which analysis is completed for a pipeline
-> sl.Pipeline
-> sl.MeasuredCell
---
entry_time = CURRENT_TIMESTAMP:timestamp #when this was entered into db
%}

classdef CellAnalyzed < dj.Manual
    
end
