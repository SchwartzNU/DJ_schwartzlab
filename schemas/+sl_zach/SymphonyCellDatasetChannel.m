%{
# A mapping of datasets to their comprising channel recordings
-> sl_zach.SymphonyCellDataset
-> sl_zach.SymphonyEpochChannel
%}
classdef SymphonyCellDatasetChannel < dj.Part
  properties(SetAccess=protected)
    master = sl_zach.Symphony;
  end

end