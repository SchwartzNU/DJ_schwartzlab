%{
#Store the morphology information of axons
->sln_cell.Axon
---
axon_proportion_along_depth: blob@raw #for SC axon, not sure how to do LGN density
axon_proportion_x: blob@raw #x axis data for the above
axon_density: float
branch_total: unsigned int
total_length: float
length_each: blob@raw #axon length of each swc, incase there are many
branch_by_total_length: float
branch_per_micron: float #branch 
convex_hull: blob@raw #convex hull of the axon, but 1 image could be >1 axon tree and thus multiple convex hull
density_each_hull:blob@raw #axon density of the convex hull
density_weighted_average:float #axon density weighted by the length
%}
classdef  RGCAxonMorph< dj.Manual
    methods(Static)
        function missing_axon_ids = axon_missing_morph()
            %TODO a function returns the ids of the axon ids that are missing morphlogy
        end

        

    end
end