%{
# Corresponds to a cell id in Symphony, could be multiple per real cell
-> sl_zach.Symphony
cell_data : varchar(64) #040518Ac1, etc.
                        #Symphony defaults to ch1, ch2 will end in '-ch2'
---
->sl_zach.CellRetina
position_x : float #optic nerve at 0,0
position_y : float
number_of_epochs : int unsigned #number of recorded epochs, including any not in db
online_label: varchar(128)      #text entered in cellType field during recording
#TODO: tags longblob... not clear
%}
classdef SymphonyCell < dj.Part
  properties(SetAccess=protected)
    master = sl_zach.Symphony;
  end

end