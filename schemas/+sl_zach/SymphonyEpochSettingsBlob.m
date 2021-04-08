%{
  # A particular setting used by an epoch
  -> sl_zach.SymphonyEpochSettings
  -> sl_zach.SymphonyEpochParameterBlob
  ---
  value : blob
  hash : int unsigned

  #the hash has the property that each unique datablob always has the same hash,
  #and that different hashes always correspond to different datablobs; but two entries
  #with the same hash are not guaranteed to be the same (though this is very likely)

%}
classdef SymphonyEpochSettingsBlob < sl_zach.SymphonySettings & dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyEpochSettings;
  end
end