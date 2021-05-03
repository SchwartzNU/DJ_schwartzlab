%{
  # A particular setting used by an epoch
  -> sl_zach.SymphonyEpochSettings
  -> sl_zach.SymphonyEpochParameterNumeric
  ---
  value : float

%}
classdef SymphonyEpochSettingsNumeric < dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyEpochSettings;
  end
end