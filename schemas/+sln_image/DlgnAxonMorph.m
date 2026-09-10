%{
#tabble to store the annotated border of dLGN for each dLGN axon images
->sln_image.AxonInBrainV2
---
pix_tol_hc: blob@raw 
edges_pixl_hc:blob@raw
pix_sandwitch_hc:blob@raw
edges_pixsand_hc:blob@raw
pix_tol_raw:blob@raw
pix_sandwitch_raw:blob@raw
branch_total: int unsigned#total number of the branch in this image
branch_each:blob@raw#for each axon bundle
total_length: float #the total length of all the 
length_each: blob@raw #axon length of each swc, unit micron, incase there are many 
convex_hull_xy: blob@raw #1 total convex hull of the whole image
axon_density_2dconv: float #axon length divided by the area of the convex hull
eccentricity_by_convhull: float #eccentricity measurement by the convex hull
%}
classdef DlgnAxonMorph < dj.Manual
    methods (Static)
        function morph_analyze(image_id, seg_id)
            %part 1 fetch morph data
            query.image_id = image_id;
            dlgn_ano = fetch(sln_image.BorderDLGN & query, '*');
            if (isempty(dlgn_ano))
                error('Cannot find annotation for image %d\n', image_id);
            end
            dlgn_lb = dlgn_ano.dlgn_loop(dlgn_ano.lateral_idx, :);
            dlgn_mb = dlgn_ano.dlgn_loop(dlgn_ano.medial_idx, :);

            scales = fetch(sln_image.Image & query, 'x_scale', 'y_scale', 'z_scale');
            trace = sln_image.AxonImageMorphV2.get_axon_morFile(image_id, seg_id); %traces in matlab strutct

            %sanity checki: is this segment/image really an axon in dLGN??
            query.seg_id = seg_id;
            axoncheck = fetch(sln_image.AxonImageAssociationV2 * sln_cell.Axon & query, '*');
            if (isempty(axoncheck))
                warning('No axon associated with image %d segment %d!!\n', image_id, seg_id);
            else
                if (~strcmp(axoncheck.brain_region, 'dLGN'))
                    error('This image %d - %d is not an axon in dLGN!\n', image_id, seg_id);
                end
            end

            %part 2 density vs dlgn lateral thing
            bundle_n = numel(trace.trace_coordinates); %number of the axon bundles
            hull = []; %convex hull ffor each bundle
            len_each = zeros([bundle_n, 1]); %total length of each bundle

            pix_toL_hc = zeros([1, 250]);
            pix_toL_raw = [];
            %miniseg_lat = cell([bundle_n, 1]);

            pix_sandwitch_hc = zeros([1, 250]);
            %miniseg_sandwich = cell([bundle_n, 1]);
            pix_sandwitch_raw = [];
            tbranch = zeros([bundle_n, 1])+1;%branch number

            xall = [];
            x_exc_prim = {};
            yall = [];
            y_exc_prim = {};
            z_exc_prim = {};
            pid_exc_prim= {};
            
            
            %mouse dLGN should not be thicker than 700micron
            %for pixel border histcounts
             edges_pixL_hc = linspace(0, 750, 251);
             edges_pixsand_hc= linspace(0, 1, 251);

            %note: remeber the unit change-- which is pixel which is micron
            for i = 1:bundle_n
                fprintf('Processing swc file: %d out of %d.\n', i, bundle_n);
                bundle = trace.trace_coordinates{i}; 
                density_pix_lat = zeros([numel(bundle.x), 1]);
                density_pix_med = zeros([numel(bundle.x), 1]);
                %density_pix_sand = zeros([numel(bundle.x), 1]);

                %copy x and y for total calculation not for density vs border
                %xall = [xall; bundle.x];
                %yall = [yall; bundle.y];
                
                exprim_filt = find(bundle.type~=2); %Tag axon -- 2
                x_exc_prim{end+1} =bundle.x(exprim_filt);
                y_exc_prim {end+1} =  bundle.y(exprim_filt);
                z_exc_prim{end+1} = bundle.z(exprim_filt);
                pid_exc_prim{end+1} = bundle.parent(exprim_filt);
                xall = [xall; bundle.x(exprim_filt)];
                yall = [yall; bundle.y(exprim_filt)];
                
                
                %measurement that includes the Tag 'Axon' -- primary axon, could be long
                for j = 2:numel(bundle.x)
                    p1 = [bundle.x(j) bundle.y(j) bundle.z(j)];
                    paidx = bundle.parent(j); %parent node of p1

                    %density as pixel to the lateral border of dlgn
                    p1_flat = p1(1:2);                  
                    density_pix_lat(j) = sln_image.Morph_Util.point2polyline(p1_flat, dlgn_lb);
                    density_pix_med(j) = sln_image.Morph_Util.point2polyline(p1_flat, dlgn_mb);

                    %counting branch
                    if (paidx ~= j-1)
                        tbranch(i) = tbranch(i) + 1; % Increment branch count
                        fprintf('current node: %d; parent node: %d\n', j, paidx);
                    end
                end
                
                %dealing lateral border density
                real_densitylat = density_pix_lat*scales.x_scale;
                pix_toL_raw = [pix_toL_raw; real_densitylat];
                pix_toL_hc = pix_toL_hc + histcounts(real_densitylat, edges_pixL_hc);

                %dealing sandwich density
                density_pix_sand = density_pix_lat./(density_pix_lat + density_pix_med);
                pix_sandwitch_raw = [pix_sandwitch_raw; density_pix_sand];
                pix_sandwitch_hc = pix_sandwitch_hc + histcounts(density_pix_sand, edges_pixsand_hc);
            end

            %measurement iterations that excludes the Tag 'Axon'
            for i = 1:bundle_n
               bundle = trace.trace_coordinates{i};
                exc_coord =[x_exc_prim{i} y_exc_prim{i} z_exc_prim{i} pid_exc_prim{i}];
                for j = 2:height(x_exc_prim)
                    p1 = [exc_coord(j, 1) exc_coord(j, 2) exc_coord(j, 3)];

                    parent_idx = exc_coord(j, 4);
                    p2 = [bundle.x(parent_idx) bundle.y(parent_idx) bundle.z(parent_idx)];
                    %calculating the segment length from
                    len_each(i) = len_each(i) + sln_image.Morph_Util.eudistance(p1, p2, ...
                        scales.x_scale, scales.y_scale, scales.z_scale);
                end
            end
            %convex hull as dot on tracing, excluding the primary axon
            hull_idx = convhull(xall, yall);
            hull = [xall(hull_idx) yall(hull_idx)];
            %area of the convex hull and density of axon part inside it...
            hull_area = polyarea(hull(:, 1), hull(:, 2));
            density_area = sum(len_each, 'all')/hull_area;
            ecc_h = sln_image.Morph_Util.ecc_fromConvHull(hull);

            %making keys
            key = {};
            key.image_id = image_id;
            key.seg_id = seg_id;
            key.pix_tol_hc = pix_toL_hc;
            key.edges_pixl_hc = edges_pixL_hc;
            key.pix_sandwitch_hc = pix_sandwitch_hc;
            key.edges_pixsand_hc = edges_pixsand_hc;
            key.pix_tol_raw = pix_toL_raw;
            key.pix_sandwitch_raw = pix_sandwitch_raw;
            key.branch_total = sum(tbranch, 'all') + bundle_n;
            key.branch_each = tbranch;
            key.total_length = sum(len_each, 'all');
            key.length_each = len_each;
            key.convex_hull_xy = hull;
            key.axon_density_2dconv = density_area;
            key.eccentricity_by_convhull = ecc_h;
            fprintf('image %d seg %d, dLGN morph data: \n', image_id, seg_id);
            disp(key);

            insert(sln_image.DlgnAxonMorph, key);
            fprintf('Insert succed!\n')
        end
       
    end
end