%{
# Corresponds to a cell id in Symphony, could be multiple per real cell
-> sl_zach.Symphony
-> sl_zach.CellRetina
---
cell_data : varchar(64)   # e.g., '043019Ac1', '121212Bc11-Ch2'
                          # only the primary entry for merged cells
position_x : float #optic nerve at 0,0
position_y : float
orientation : enum('ventral down','unknown')
number_of_epochs : int unsigned #number of recorded epochs, including any not in db
online_label = NULL: varchar(128)      #text entered in cellType field during recording
#TODO: tags longblob... not clear
%}
classdef SymphonyCell < dj.Part
  properties(SetAccess=protected)
    master = sl_zach.Symphony;
  end

end