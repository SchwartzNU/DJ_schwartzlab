%{
# Git state of the acquisition code when the data file was created (Symphony 3 writes it as experiment properties)
-> sln_symphony.Experiment
repository : varchar(64)        # symphony3_matlab, sa-labs-extension, stage3_testbed, stagepc/...
---
branch : varchar(64)
commit_hash : varchar(40)
ahead : smallint unsigned       # commits not pushed to origin when the file was created
dirty : tinyint unsigned        # 1 if the checkout had uncommitted changes
%}
classdef ExperimentCodeVersion < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Experiment;
end
end
