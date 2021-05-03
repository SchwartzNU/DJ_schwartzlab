%{
  # A particular setting used by an experiment
  -> sl_zach.SymphonyProtocolSettings
  -> sl_zach.SymphonyProtocolParameterNumeric
  ---
  value : float

%}
classdef SymphonyProtocolSettingsNumeric < sl_zach.SymphonySettings & dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyProtocolSettings;
  end
end