%{
# Calibration values for a LightCrafter LED
-> sln_symphony.Calibration
-> sln_symphony.LED
---
rod_overlap: float
s_cone_overlap: float
m_cone_overlap: float

#polynomial fit values, by degree
fit_6 : float 
fit_5 : float 
fit_4 : float 
fit_3 : float 
fit_2 : float 
fit_1 : float
%}
classdef CalibrationLED < sln_symphony.ExperimentPart
properties(SetAccess=protected)
  master = sln_symphony.Calibration;
end
end