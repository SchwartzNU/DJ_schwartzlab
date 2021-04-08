%{
  # A particular setting used by an epoch
  -> sl_zach.SymphonyEpochSettings
  -> sl_zach.SymphonyEpochParameterBool
  ---
  value : enum('false','true')  #TODO: dj does not yet support bool...

%}
classdef SymphonyEpochSettingsBool < sl_zach.SymphonySettings & dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyEpochSettings;
  end
end