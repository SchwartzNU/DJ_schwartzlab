%{
# A single channel in a Symphony epoch
-> sl_zach.SymphonyEpoch
channel : tinyint unsigned 
---
amp_mode : enum('Iclamp', 'Vclamp')
amp_hold : float
recording_mode : enum('Cell attached', 'Whole cell') #TODO: we need unknown field here, right?
data_link: varchar(512)

%}
classdef SymphonyEpochChannel < dj.Part
  properties(SetAccess=protected)
    master = sl_zach.Symphony;
  end

end