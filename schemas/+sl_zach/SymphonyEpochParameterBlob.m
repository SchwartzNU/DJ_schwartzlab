%{
  # A blob parameter used by an epoch
  parameter_name: varchar(64)     # unique parameter name
%}

classdef SymphonyEpochParameterBlob < dj.Lookup
end