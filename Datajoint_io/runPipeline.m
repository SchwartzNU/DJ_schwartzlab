function [] = runPipeline(pipeline, loadFirst, export)
if nargin < 3
    export = false;
end
if nargin < 2
    loadFirst = true;
end

pipelineDir = [getenv('pipelines_folder'), pipeline filesep];
if ~exist(pipelineDir, 'dir')
    fprintf('Error: could not find pipeline folder %s\n', pipelineDir);
    return;
end

if exist([pipelineDir, 'dataGroup.mat'], 'file')
    load([pipelineDir, 'dataGroup.mat'], 'workingGroup');    
else
    fprintf('Error: could not load dataGroup.mat\n');
end
    
if exist([pipelineDir, 'analysisSteps.mat'], 'file')
    load([pipelineDir, 'analysisSteps.mat'], 'analysisSteps'); 
    if export
        load([pipelineDir, 'analysisSteps.mat'], 'exportStates'); 
    end
else
    fprintf('Error: could not load analysisSteps.mat\n');
end

if export
    runFullPipeline(pipeline, workingGroup, analysisSteps, loadFirst, exportStates);
else
    runFullPipeline(pipeline, workingGroup, analysisSteps, loadFirst);
end