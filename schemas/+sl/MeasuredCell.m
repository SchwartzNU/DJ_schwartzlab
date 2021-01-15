%{
# MeasuredCell
cell_unid:      int unsigned auto_increment     # unique ID for each cell
-> sl.Animal
cell_id: varchar(64) #for Symphony cells: 040518Ac1, ...
                     #defaults to ch1, but could include -ch2 or multiple
                     #cells separated by commas
                     #but it could have a different form for different
                     #types of measurements
---
%}

classdef MeasuredCell < dj.Manual
    
end
