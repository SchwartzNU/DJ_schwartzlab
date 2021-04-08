%{
  # A particular setting used by an experiment
  -> sl_zach.SymphonyProtocolSettings
  -> sl_zach.SymphonyProtocolParameterBlob
   ---
  value : blob
  hash : int unsigned

  #the hash has the property that each unique datablob always has the same hash,
  #and that different hashes always correspond to different datablobs; but two entries
  #with the same hash are not guaranteed to be the same (though this is very likely)

%}
classdef SymphonyProtocolSettingsBlob < sl_zach.SymphonySettings & dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyProtocolSettings;
  end
end