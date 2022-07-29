%{
#A reagent for tissue staining: primary, secondary, flurophore conjugate, etc.
reagent_id : int unsigned AUTO_INCREMENT     # unique id
---
vendor_name : varchar(32)    # vendor for this reagent
catalg_number : varchar(32)    # catalog number
reagent_info = NULL : varchar(256) # additional information about the reagent
%}

classdef StainReagent < dj.Lookup

end