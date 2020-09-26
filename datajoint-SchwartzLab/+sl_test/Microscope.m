%{
# Microscope 
scope_name : varchar(32)  # name of scope
----
-> sl_test.ImagingModality
scope_location : enum('Schwartz lab', 'imaging core', 'other') # location 

notes: varchar(128)                                            # unstructured
%}

classdef Microscope < dj.Lookup
    
end
