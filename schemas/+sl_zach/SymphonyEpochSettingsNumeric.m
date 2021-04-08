%{
  # A particular setting used by an epoch
  -> sl_zach.SymphonyEpochSettings
  -> sl_zach.SymphonyEpochParameterNumeric
  ---
  value : float

%}
classdef SymphonyEpochSettingsNumeric < sl_zach.SymphonySettings & dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyEpochSettings;
  end
end