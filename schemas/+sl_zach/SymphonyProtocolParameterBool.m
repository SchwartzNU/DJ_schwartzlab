%{
  # A boolean parameter used by an experiment
  parameter_name: varchar(64)     # unique parameter name
%}

classdef SymphonyProtocolParameterBool < dj.Lookup
end