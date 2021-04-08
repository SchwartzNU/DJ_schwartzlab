%{
# A group of epochs created in Symphony Analysis
-> sl_zach.SymphonyCell
dataset_name: varchar(128)
---
#TODO: verify that other fields from sl.Dataset should be here... i think not?
%}
classdef SymphonyCellDataset < dj.Part
  properties(SetAccess=protected)
    master = sl_zach.Symphony;
  end

end