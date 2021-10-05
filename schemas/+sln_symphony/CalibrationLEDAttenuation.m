%{
# The amount an LED's intensity is attenuated by an NDF
-> sln_symphony.CalibrationLED
-> sln_symphony.CalibrationNDF
---
attenuation: float
%}
classdef CalibrationLEDAttenuation < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Calibration;
end
end