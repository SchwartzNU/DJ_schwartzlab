function [] = runPipeline(pipeline, user, overwriteResults, export)
if nargin < 4
    export = false;
end
if nargin < 3
    overwriteResults = false;
end

if ~exist([getenv('pipelines_folder'), pipeline], 'dir')
    mkdir([getenv('pipelines_folder'), pipeline]);
end

queryStruct = sl_mutable.PipelineQuery & sprintf('pipeline_name="%s"',pipeline);
datasets = runPipelineQuery(queryStruct.fetch('*'));

if ~overwriteResults    
    %get only unanalyzed ones
    analyzed = sl_mutable.DatasetAnalyzed & sprintf('pipeline_name="%s"', pipeline);
    datasets = datasets - analyzed;
end

workingGroup.primaryKeyStruct = datasets.fetch();
query_state = fetch1(queryStruct,'query_state');
workingGroup.searchTable = makeSearchTable(query_state.currentTables, user);

analysisStepsQuery = sl_mutable.PipelineAnalysisSteps & sprintf('pipeline_name="%s"', pipeline);
analysisSteps = analysisStepsQuery.fetch1('analysis_steps');

if export
    exportStates = analysisStepsQuery.fetch1('export_states');
    runFullPipeline(pipeline, workingGroup, analysisSteps, false, exportStates);
else
    runFullPipeline(pipeline, workingGroup, analysisSteps, false);
end