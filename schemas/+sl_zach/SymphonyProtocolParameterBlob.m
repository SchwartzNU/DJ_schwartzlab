%{
  # A blob parameter used by an experiment
  parameter_name: varchar(64)     # unique parameter name
%}

classdef SymphonyProtocolParameterBlob < dj.Lookup
end