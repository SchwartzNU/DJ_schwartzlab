%{
  # A boolean parameter used by an epoch
  parameter_name: varchar(64)     # unique parameter name
%}

classdef SymphonyEpochParameterBool < dj.Lookup
end