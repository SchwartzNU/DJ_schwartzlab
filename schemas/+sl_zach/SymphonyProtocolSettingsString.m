%{
  # A particular setting used by an experiment
  -> sl_zach.SymphonyProtocolSettings
  -> sl_zach.SymphonyProtocolParameterString
  ---
  value : varchar(64)

%}
classdef SymphonyProtocolSettingsString < sl_zach.SymphonySettings & dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyProtocolSettings
  end
end