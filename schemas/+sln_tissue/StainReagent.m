%{
#A reagent for tissue staining: primary, secondary, flurophore conjugate, etc.
reagent_id : int unsigned AUTO_INCREMENT     # unique id
---
suggested_dilution = NULL : varchar(32) # 1:X dilution
reagent_name : varchar(64)  #reagent name
catalog_name : varchar(128) #name in catalog to search online
-> sln_tissue.Vendor   # vendor for this reagent
catalog_number : varchar(32)    # catalog number
reagent_info = NULL : varchar(256) # additional information about the reagent
%}

classdef StainReagent < dj.Lookup

end