%{
  # A parameter to not include in the database in standard way
  parameter_name: varchar(64)     # unique parameter name

%}

classdef SymphonyParameterExclude < dj.Lookup
end