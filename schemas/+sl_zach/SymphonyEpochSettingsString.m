%{
  # A particular setting used by an experiment
  -> sl_zach.SymphonyEpochSettings
  -> sl_zach.SymphonyEpochParameterString
  ---
  value : varchar(64)

%}
classdef SymphonyEpochSettingsString < dj.Part
  properties(SetAccess=protected)
    master = sl_zach.SymphonyEpochSettings;
  end
end