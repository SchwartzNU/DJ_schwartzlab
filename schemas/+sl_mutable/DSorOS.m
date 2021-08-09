%{
# Table to store our judgements of whether cells are DS or OS from MB or DG data
-> sl.MeasuredCell
---
selectivity = NULL    : enum('DS','OS', 'not DS', 'not OS')
stim_type  =  NULL    : enum('moving bars', 'drifting gratings')
%}

classdef DSorOS < dj.Manual
    
end
