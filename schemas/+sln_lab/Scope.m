%{
# Microscope
scope_name : varchar(32)                  # microscope name, for CAM ones these should match the CAM names
---
scope_location : enum('Tarry 5-726', 'Tarry 5-722', 'CAM') #physical location of the scope
scope_info : varchar(126)     #information about the scope and/or a link to a website with more information about its details
%}
classdef Scope < dj.Lookup
    
end