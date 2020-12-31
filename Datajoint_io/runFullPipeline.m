function [] = runFullPipeline(pipeline, workingGroup, analysisSteps, loadFirst)
%TODO - maybe a log file
Nsteps = length(analysisSteps);
workingQuery = workingGroup.searchTable & workingGroup.primaryKeyStruct;

for i=1:Nsteps
    funcType = analysisSteps(i).funcType;
    funcName = analysisSteps(i).funcName;
    P = analysisSteps(i).P;
        
    if loadFirst
        [analysisOutput, loaded_some, missed_some] = loadResult(pipeline, funcType, funcName, workingQuery);
        if missed_some
            if loaded_some
                previousLoad = analysisOutput;
            else
                previousLoad = [];
            end    
            analysisOutput = runAnalysis(pipeline, funcType, funcName, P, workingQuery, previousLoad);            
        end
    else
        analysisOutput = runAnalysis(pipeline, funcType, funcName, P, workingQuery, []);
    end
    
    writeResult(pipeline, funcType, funcName, P, analysisOutput, true)    
end