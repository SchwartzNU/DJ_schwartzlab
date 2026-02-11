%{
#Store the morphology information of axons
->sln_image.AxonInBrain
---
axon_proportion_along_depth: blob@raw #for SC axon, currently SC only 
axon_density_along_depth: blob@raw #density in projected length along the same axis
axon_depth_axis: blob@raw #axis going from the surface of SC to deep
branch_total: int unsigned#total number of the branch in this image
branch_each:blob@raw#for each axon bundle
total_length: float #the total length of all the 
length_each: blob@raw #axon length of each swc, unit micron, incase there are many 
convex_hull_xy: blob@raw #1 total convex hull of the whole image
axon_density_2dconv: float #axon length divided by the area of the convex hull
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

        function axon_morph_analyze(image_id)
            trace = sln_cell.AxonImageMorph.get_axon_morFile(image_id); %traces in matlab strutct
            bundle_n = numel(trace.trace_coordinates); %number of the axon bundles
            hull = []; %convex hull ffor each bundle
            len_each = zeros([bundle_n, 1]); %total length of each bundle

            density_dep = cell([bundle_n,1]);
            tbranch = zeros([bundle_n, 1])+1;%branch number
            %area_dense_each = zeros([bundle_n, 1]);
            %ecc_h = zeros([bundle_n, 1]);
            %each bundle is a cell in trace_coordinate
            q = sprintf('image_id = %d', image_id);
            scales = fetch(sln_image.Image & q, 'x_scale', 'y_scale', 'z_scale');

            xall = [];
            yall = [];
            %note: remeber the unit change-- which is pixel which is micron
            for i = 1:bundle_n
                bundle = trace.trace_coordinates{i}; 
                density_this = zeros([numel(bundle.x)-1, 2]);
                xall = [xall; bundle.x];
                yall = [yall; bundle.y];
                for j = 2:numel(bundle.x)
                    p1 = [bundle.x(j) bundle.y(j) bundle.z(j)];
                    paidx = bundle.parent(j);
                    p2 = [bundle.x(paidx) bundle.y(paidx) bundle.z(paidx)];
                    len_each(i) = len_each(i) + sln_cell.AxonImageMorph.eudistance(p1, p2, ...
                        scales.x_scale, scales.y_scale, scales.z_scale);

                    %density vs depth
                    p1_2d = [bundle.x(j) bundle.y(j)];
                    p2_2d = [bundle.x(paidx) bundle.y(paidx)];
                    [pjp1x, pjp1y] = sln_cell.AxonImageMorph.project_to_ax(p1_2d(1), p1_2d(2), ...
                        trace.axon_axis.slope, trace.axon_axis.intercept);
                    start_to_cross = [pjp1x pjp1y]-trace.axon_axis.startPoint;
                    start_dis = norm(start_to_cross);

                    [pjp2x, pjp2y] = sln_cell.AxonImageMorph.project_to_ax(p2_2d(1), p2_2d(2),...
                        trace.axon_axis.slope, trace.axon_axis.intercept);
                    enddis = norm([pjp2x pjp2y]-trace.axon_axis.startPoint);

                    if (start_dis < enddis)
                        density_this(j,1) = start_dis;
                        density_this(j, 2) = enddis;

                    else
                        density_this(j, 1) = enddis;
                        density_this(j, 2) = start_dis;
                    end
                  density_dep{i} = density_this;

                    %this may not be the optimal thing to do, could take a lot of time to calculate
                    %is this a branch?
                    if (paidx == i-1)
                        tbranch(i) = tbranch(i) + 1; % Increment branch count
                    end
                end                 
            end

            %measurement relating to convehull: convhull shape/size, density in 2D, convhull eccentricity
            %convexhull on 2D
            hull_idx = convhull(xall, yall);
            hull = [xall(hull_idx) yall(hull_idx)];
            %area of the convex hull and density of axon part inside it...
            hull_area = polyarea(hull(:, 1), hull(:, 2));
            density_area = sum(len_each, 'all')/hull_area;
            %eccentricity.
            %TODO check if this is accurate later
            hull_cx = mean(xall(hull_idx), 'all');
            hull_cy = mean(yall(hull_idx), 'all');

            %offset all dots in traces
            x_offseted  = bundle.x - hull_cx;
            y_offseted = bundle.y - hull_cy;

            cov_matrix = cov([x_offseted, y_offseted]);
            [~, eigenvalues] = eig(cov_matrix);
            lambda = diag(eigenvalues);
            % Principal axes lengths (proportional to sqrt of eigenvalues)
            maxlambda = max(lambda);
            minlambda = min(lambda);
            a = sqrt(maxlambda);  % semi-major axis
            b = sqrt(minlambda);  % semi-minor axis
            ecc_h = sqrt(1-(b/a)^2);

            binmin = 0;
            binmax = 2893; %sqrt(2048^2 + 2044^2), number of hypothetical pixel number along the diagonal line of the image
            binsize = 500;
            sample_seg = linspace(binmin, binmax, binsize);
            binCount = zeros([binsize-1, 1]);
            for i = 1:bundle_n
                [segn, ~] = size(density_dep{i});
                for j = 1:segn
                    edg1 = (sample_seg>density_dep{i}(j, 1));
                    edg2 = (sample_seg<density_dep{i}(j, 2));
                    if (sum(edg1&edg2)==0)
                        edge_idx= min(find(edg1));
                    else
                        edge_idx = find(edg1 & edg2)-1;
                    end
                    %the segment overlaps at leat 2 bins
                    binCount(edge_idx) = binCount(edge_idx) +1;
                    %fprintf('%d %d\n', sum(binCount), segn);
                end

            end


        %inserting part;
        key = {};
        key.image_id = image_id;
        %TODO FILL THIS
        %axon depth density and proportion along the depth
        sample_seg = sample_seg(2:end);
        key.axon_depth_axis = transpose(sample_seg) *scales.x_scale;
        key.axon_density_along_depth = binCount;
        key.axon_proportion_along_depth = binCount/sum(binCount, 'all');

        %branch number
        key.branch_each = tbranch;
        key.branch_total = sum(tbranch, 'all');

        %length
        key.length_each = len_each;
        key.total_length = sum(len_each, 'all');

        %convex hull
        key.convex_hull_xy = hull;
        key.axon_density_2dconv = density_area;
        key.eccentricity_by_convhull = ecc_h;
        disp(key);
        %uploading
        try
            C = dj.conn;
            C.startTransaction;
            insert(sln_cell.AxonImageMorph, key);
            C.commitTransaction;

            fprintf('Inserting success!\n');
            
        catch ME
            disp(ME);
        end

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

            linep1 = [p1x linep1y];
            linep2 = [0.5*p1x linep2y];

            line_vec = linep1- linep2;
            to_dot = [p1x p1y] - linep1;
            t = dot(to_dot, line_vec)/dot(line_vec, line_vec);
            nearest_p = linep1 + t*line_vec;
            newx = nearest_p(1);
            newy = nearest_p(2);
        end



    end
end