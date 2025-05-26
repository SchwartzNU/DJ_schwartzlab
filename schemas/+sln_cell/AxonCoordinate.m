classdef AxonCoordinate < dj.Computed
    %store the compuated values of RGC axons in brain
    properties(Constant)
        
        definition = [
            "%{"
            "# automatically updated table to store axon location"
            "-> sln_cell.Axon"
            "---"
            "medial_lateral: double"
            "distance_from_1st_slice: double"
            "%}"
        ]
    end

    methods
        function self = AxonCoordinate()
            self.restrict(dj.Relvar); % optional — can omit
        end
    end
methods (Access=protected)


    function makeTuples(self, key)
        image_ids = fetch(sln_image.AxonImageAssociation & key, 'image_id');

        all_ml = zeros([1, numel(imag_ids)]);
        all_ap = zeros([1, numel(image_ids)]);
        for i = 1:numel(image_ids)
           query.image_id = image_ids(i).image_id;
           wholeid = fetch1(sln_image.AxonInBrain & query, 'whole_brain');
          
          wholeim_query.ref_image_id = wholeid;
          wholeim = fetch(sln_image.WholeBrainImage & wholeim_query,  'slide_num', 'brain_num', 'tissue_id', 'midline_slope', 'midline_intercept');

          %look for how many whole-brain-images with smaller slide or brain num are there
         tissue_str = append('tissue_id = ', num2str(wholeim.tissue_id));
         slide_str = append('slide_num = ', num2str(wholeim.slide_num));
         brain_str = append('brain_num <', num2str(wholeim.brain_num));
         less_brain = numel(fetch(sln_image.WholeBrainImage & tissue_str &slide_str&brain_str));

         %look for how many whole-brain images with smaller number of slide
         slide_str = append('slide_num<', num2str(wholeim.slide_num));
         less_slide = numel(fetch(sln_image.WholeBrainImage & tissue_str & slide_str));
       
         %query for slicing thickness
         thickness = fetch(sln_tissue.BrainSliceBatch & tissue_str, 'thickness');
         %key. distance_from_1st_slice= thickness * (less_brain+less_slide);
         all_ap(i) = thickness * (less_brain + less_slide);
         
         %get the medial lateral information
         qstr = append('image_id = ', num2str(image_ids(i).image_id));
         c = fetch(sln_image.AxonInBrain & qstr, 'centroid_x', 'centroid_y');
         all_ml(i) =  abs(wholeim.midline_slope * c.centroid_x - c.centroid_y + wholeim.midline_intercept)/sqrt(wholeim.midline_slope ^2 + 1);
         
        end
        %the relative medial/lateral and anterior-posterior is the average of all the axinInBrain images that contains this axon 
        key.medial_lateral = mean(all_ml);
        key.distance_from_1st_slice = mean(all_ap);

        %try insert
        try
            self.insert(key);
        catch ME
            rethrow (ME);
        end

    end
end
end