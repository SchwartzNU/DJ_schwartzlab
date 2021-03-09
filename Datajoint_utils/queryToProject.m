function [] = queryToProject(q, projectName)
global ANALYSIS_FOLDER;

cell_ids = q.fetchn('cell_id');

projectFolder = [ANALYSIS_FOLDER 'Projects' filesep projectName];
if ismac
    eval(['!rm -rf ' projectFolder]);
    eval(['!mkdir ' projectFolder]);
elseif ispc
    if exist(projectFolder, 'dir')
        rmdir(projectFolder) % won't remove if the directory already exists
    end
    mkdir(projectFolder)
end

fid = fopen([projectFolder filesep 'cellNames.txt'], 'w');s

for i=1:length(cell_ids)
    if ~isempty(cell_ids{i})
        fprintf(fid, '%s\n', cell_ids{i});
    end
end
fclose(fid);