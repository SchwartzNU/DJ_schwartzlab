%{
#store the compuated values of RGC axons in brain
-> sln_cell.Axon
---
medial_lateral: double
anterior_posterior: double
%}

classdef AxonCoordinate < dj.Computed
properties (Constant)
    keySource = aggr( proj(sln_cell.Axon, 'axon_id') * sln_image.AxonImageAssociation * proj(sln_image.AxonInBrain, 'medial_lateral', 'distance_from_fist_slice'),...
        proj(proj(sln_cell.Axon, 'axon_id') * sln_image.AxonImageAssociation * proj(sln_image.AxonInBrain, 'medial_lateral', 'distance_from_fist_slice'), 'axon_id'),...
        'AVG(medial_lateral)->mean_ml', 'AVG(distance_from_fist_slice)->mean_ap ');
end

methods (Access=protected)
    function makeTuples(self, key)

        data = fetch(self.keySource & key, '*');
        % result  = key;
        result.axon_id = key.axon_id;
        result.medial_lateral = data.mean_ml;
        result.anterior_posterior = data.mean_ap;
        
        %testing codes don't use
        % key.medial_lateral = 0;
        % key.anterior_posterior = 0;

        %try insert
        %key = rmfield(key, 'image_id');
        self.insert(result);

    end
end
end