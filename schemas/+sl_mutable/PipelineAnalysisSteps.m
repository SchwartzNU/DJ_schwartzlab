%{
# PipelineAnalysisSteps stores a structure with the analysis steps for the pipeline
-> sl.Pipeline
---
analysis_steps : longblob #struct array with the analysis steps
export_states : longblob #struct array with the hdf5 export information
%}

classdef PipelineAnalysisSteps < dj.Manual
    
end
