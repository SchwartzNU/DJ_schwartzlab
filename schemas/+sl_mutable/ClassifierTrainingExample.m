%{
# Cells used in the training set for the classifier
-> sl.SymphonyRecordedCell
version     : tinyint unsigned # the version of the classifier
---
-> [nullable] sl.CellType # the label for this cell, if applicable
%}
classdef ClassifierTrainingExample < dj.Manual
end