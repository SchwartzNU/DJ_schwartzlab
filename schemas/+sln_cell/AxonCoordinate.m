%{
#store the compuated values of RGC axons in brain
-> sln_cell.Axon
---
medial_lateral: double
anterior_posterior: double
%}

classdef AxonCoordinate < dj.Computed
    properties (Constant)
        keySource = sln_cell.Axon;
    end

    methods (Access=protected)
        function makeTuples(self, key)
            try
                qstruct.axon_id = key.axon_id;
                association = fetch( sln_image.AxonImageAssociation & qstruct, 'image_id');
                ap_all = zeros([numel(association), 1]);
                ml_all = zeros([numel(association),1]);
                for i = 1:numel(association)
                    im.image_id = association(i).image_id;
                    result = fetch(sln_image.AxonInBrain & im, 'medial_lateral', 'distance_from_fist_slice');
                    ap_all(i) = result.distance_from_fist_slice;
                    ml_all(i) = result.medial_lateral;
                end
                
               fprintf('Axon %d...\n', qstruct.axon_id);
                fprintf('Medial lateral: \n');
                disp(ml_all);
                fprintf('Anterior Posterior: \n');
                disp(ap_all);
                key.medial_lateral = mean(ml_all);
                key.anterior_posterior = mean(ap_all);

                % testing codes don't use
                % key.medial_lateral = 0;
                % key.anterior_posterior = 0;

                %try insert
                self.insert(key);
                fprintf('Axon coordinate added:\n');
                disp(key);
            catch ME
                rethrow(ME);
            end

    end
end
end