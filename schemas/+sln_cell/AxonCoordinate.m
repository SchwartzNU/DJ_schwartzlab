%{
#store the compuated values of RGC axons in brain
-> sln_cell.Axon
---
medial_lateral: double
distance_from_1st_slice: double
%}

classdef AxonCoordinate < dj.Computed
properties (Constant)
    keySource = sln_cell.Axon * sln_image.AxonImageAssociation * sln_image.AxonInBrain;
end

methods (Access=protected)
    function makeTuples(self, key)
        
        image_ids = fetch(sln_image.AxonImageAssociation & sprintf('axon_id = %d', key.axon_id), 'image_id');

        all_ml = zeros([1, numel(image_ids)]);
        all_ap = zeros([1, numel(image_ids)]);
        for i = 1:numel(image_ids)
            searchkey.image_id =  image_ids(i).image_id;
            spinningdata = fetch(sln_image.AxonInBrain & searchkey, '*');
            all_ml(i) = spinningdata.medial_lateral;
            all_ap(i) = spinningdata.distance_from_fist_slice;
        end
        %the relative medial/lateral and anterior-posterior is the average of all the axinInBrain images that contains this axon 
        key.medial_lateral = mean(all_ml);
        key.distance_from_1st_slice = mean(all_ap);

        inserting = {};
        inserting.axon_id = key.axon_id;
        inserting.medial_lateral = key.medial_lateral;
        inserting.distance_from_1st_slice = key.distance_from_1st_slice;

        %try insert
        try
            self.insert(inserting);
        catch ME
            rethrow (ME);
        end

    end
end
end