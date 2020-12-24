function [date, rig] = cellID_to_dateAndRig(cell_id)
m = cell_id(1:2);
d = cell_id(3:4);
y = ['20' cell_id(5:6)];
rig = cell_id(7);
date = sprintf('%s-%s-%s',y,m,d);