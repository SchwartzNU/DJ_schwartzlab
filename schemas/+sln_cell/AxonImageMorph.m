%{
#Store the morphology information of axons
->sln_image.AxonInBrain
---
axon_proportion_along_depth: blob@raw #for SC axon, currently SC only 
axon_density_along_depth: blob@raw #density in projected length along the same axis
axon_depth_axis: blob@raw #axis going from the surface of SC to deep
branch_total: unsigned int #total number of the branch in this image
branch_each:unsigned int #for each axon bundle
total_length: float #the total length of all the 
length_each: blob@raw #axon length of each swc, incase there are many 
convex_hull_xy: blob@raw #convex hull of the axon, but 1 image could be >1 axon tree and thus multiple convex hull
axon_density_2dconv: float
eccentricity_by_convhull: float #eccentricity measurement by the convex hull
%}
classdef  AxonImageMorph< dj.Manual

    methods(Static)
        function axon_trace_data = get_axon_morFile(image_id)
            if(isnumeric(image_id))
                q = sprintf('image_id = %d', image_id);
            else
                error('Axon id should be a number!\n');
            end

            result = sln_image.AxonMorphFile & q;
            if (~isempty(result))
                axon_trace_data = fetch(result, 'trace_coordinates', 'axon_axis');
            else
                error('Cannot trace for axon %d\n', image_id);
            end
        end

        function axon_morph_anlyze(image_id)
            trace = get_axon_morFile(image_id); %traces in matlab strutct
            bundle_n = numel(trace.trace_coordinate); %number of the axon bundles
            hulls = cell([bundle_n, 1]); %convex hull ffor each bundle
            len_each = zeros([bundle_n, 1]); %total length of each bundle

            density_dep = cell([bundle_n,1]);
            tbranch = zeros([bundle_n, 1]);%branch number
            area_dense_each = zeros([bundle_n, 1]);
            ecc_h = zeros([bundle_n, 1]);
            %each bundle is a cell in trace_coordinate
            q = sprintf('image_id = %d', image_id);
            scales = fetch(sln_image.Image & q, 'x_scale', 'y_scale', 'z_sacle');


            %total length, this is a 3d measurement
            %note: remeber the unit change-- which is pixel which is micron
            for i = 1:bundle_n
                bundle = trace.trace_coordinate{i}; 
                density_this = zeros([numel(bundle.x)-1, 2]);
                if (i==1)
                    nearest = inf;
                    furtherest = -inf;
                end
                %xall = [xall bundle.x];
                %yall = [yall bundle.y];
                for j = 2:numel(bundle.x)
                    p1 = [bundle.x(j) bundle.y(j) bundle.z(j)];
                    paidx = bundle.parent(j);
                    p2 = [bundle.x(paidx) bundle.y(paidx) bundle.z(paidx)];
                    len_each(i) = len_each(i) + eudistance(p1, p2, scales.x_scale, scales.y_scale, scales.z_scale);

                    %density vs depth
                    p1_2d = [bundle.x(j) bundle.y(j)];
                    p2_2d = [bundle.x(paidx) bundle.y(paidx)];
                    [pjp1x, pjp1y] = project_to_ax(p1_2d(1), p1_2d(2), ...
                        bundle(i).axon_axis.slope, bundle(i).axon_axis.intercept);
                    start_to_cross = [pjp1x pjp1y]-bundle(i).axon_axis.startPoint;
                    start_dis = norm(start_to_cross);

                    [pjp2x, pjp2y] = project_to_ax(p2_2d(1), p2_2d(2),...
                        bundle(i).axon_axis.slope, bundle(i).axon_axis.intercept);
                    enddis = norm([pjp2x pjp2y]-bundle(i).axon_axis.startPoint);


                    if (start_dis < enddis)
                        density_this(j,1) = start_dis;
                        density_this(j, 2) = enddis;

                    else
                        density_this(j, 1) = enddis;
                        density_this(j, 2) = start_dis;
                    end

                  %p1x, p1y, p2x, p2y, start_ps, slope_cpt

                    %this may not be the optimal thing to do, could take a lot of time to calculate
                    %is this a branch?
                    if (paidx == i-1)
                        tbranch(i) = tbranch(i) + 1; % Increment branch count
                    end
                end

                %measurement relating to convehull: convhull shape/size, density in 2D, convhull eccentricity

                %convexhull on 2D
                hull_idx = convhull(bundle.x, bundle.y);
                hulls{i} = [bundle.x(hull_idx) bundle.y(hull_idx)];
                %area of the convex hull and density of axon part inside it...
                hull_area = polyarea(bundle.x(hull_idx), bundle.y(hull_idx));
                area_dense_each(i) = len_each(i)/hull_area;
                %eccentricity. 
                %TODO check if this is accurate later
                hull_cx = mean(bundle.x(hull_idx), 'all');
                hull_cy = mean(bundle.y(hull_idx), 'all');

                %offset all dots in traces
                x_offseted  = bundle.x - hull_cx;
                y_offseted = bundle.y - hull_cy;

                cov_matrix = cov([x_offseted, y_offseted]);
                [~, eigenvalues] = eig(cov_matrix);
                lambda = diag(eigenvalues);
                % Principal axes lengths (proportional to sqrt of eigenvalues)
                a = sqrt(max(lambda));  % semi-major axis
                b = sqrt(min(lambda));  % semi-minor axis
                ecc_h(i) = sqrt(1-(b/a)^2);     
                 density_dep{i} = density_this;
                 
            end
            %include all bundles in this image how???
            %find the min and max of the density axis first
            
            min = norm(trace.axon_axis.startPoint);
            max = 951 * scales.x_scale + min;
            binsize = 951;
            sample_seg = linspace(min, max, binsize);
            binCount = zeros([binsize-1, 1]);
            for i = 1:bundle_n
                [segn, ~] = size(density_dep{i});
                for j = 1:segn
                    edg1 = (sample_seg>density_dep{i}(j, 1));
                    edg2 = (sample_seg<density_dep{i}(j, 2));
                    edge_idx = find(edg1 & edg2)-1;
                    %the segment overlaps at leat 2 bins
                    binCount(edge_idx) = binCount(edge_idx) +1;
                end

            end


        %inserting part;
        key = {};
        %TODO FILL THIS
        upload_morpho(key);
        end

        function dis = eudistance(p1, p2, xs, ys, zs)
            %is this right? regarding the scale issue
            x_d = (p1(1)-p2(1))^2*xs^2;
            y_d = (p1(2)- p2(2))^2 * ys^2;
            z_d = (p1(3) - p2(3))^2 * zs^2;
            dis = sqrt(x_d+y_d+z_d);
        end

        function [newx, newy] = project_to_ax(p1x, p1y,  slope, intercept)
            linep1y = p1x*slope + intercept;
            linep2y = p1x*0.5*slope + intercept;

            linep1 = [p1x, linep1y];
            linep2 = [0.5*p1x, linep2y];

            line_vec = linep2- linep1;
            to_dot = [p1x p1y] - linep1;
            t = dot(to_dot, line_vec)/norm(line_vec);
            nearest_p = linep1 + t*line_vec;
            newx = nearest_p(1);
            newy = nearest_p(2);
        end

        function upload_morpho(key)
        end



    end
end