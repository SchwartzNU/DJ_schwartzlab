%{
# DatasetAnalyzed table stores datasets for which analysis is completed for a pipeline
-> sl.Pipeline
-> sl.Dataset
---
entry_time = CURRENT_TIMESTAMP:timestamp #when this was entered into db
%}

classdef DatasetAnalyzed < dj.Manual
    
end
