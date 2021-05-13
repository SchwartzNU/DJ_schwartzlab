%{
  # A string parameter used by an epoch
  parameter_name: varchar(64)     # unique parameter name
%}

classdef SymphonyEpochParameterString < dj.Lookup
end