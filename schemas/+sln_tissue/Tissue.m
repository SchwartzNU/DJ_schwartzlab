%{
#Tissue
tissue_id : int unsigned AUTO_INCREMENT
---
(owner) -> sln_lab.User
tissue_info = NULL          : varchar(256)
%}

classdef Tissue < dj.Manual % I should make this dj.Shared
    methods(Static)
        function q = active()
            q = sln_tissue.Tissue & sln_tissue.TissueActive;
        end

        function q = inactive()
            q = sln_tissue.Tissue - sln_tissue.TissueActive;
        end
    end

    methods
        function activate(self)
            insert(sln_tissue.TissueActive,fetch(self));
        end

        function deactivate(self)
            delQuick(sln_tissue.TissueActive & fetch(self));
        end
    end
    
end