%{
  # A particular setting used by an experiment
  -> sl_zach.SymphonyProtocolSettings
  -> sl_zach.SymphonyProtocolParameterBool
  ---
  value : enum('false','true')  #TODO: dj does not yet support bool...

%}
classdef SymphonyProtocolSettingsBool < sl_zach.SymphonySettings & dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyProtocolSettings;
  end
end