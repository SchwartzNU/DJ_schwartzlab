%{
# Neutral density filter
-> sln_symphony.Calibration
value: tinyint unsigned
%}
classdef CalibrationNDF < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Calibration;
end
end