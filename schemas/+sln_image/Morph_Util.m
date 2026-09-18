classdef Morph_Util
%collection of functions for axon morphology analysis

    properties

    end

    methods (Static)

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

        function [d, idx, cp] = point2polyline(p, V)
            % Distance from a 2D point to a polyline.
            %   p : 1x2 (or 2x1) point
            %   V : nx2 vertices of the polyline
            %   d   : distance to the nearest segment
            %   idx : index of that segment (from V(idx,:) to V(idx+1,:))
            %   cp  : closest point on the polyline

            p = p(:).';
            if size(V,1) < 2
                d = norm(p - V);  idx = 1;  cp = V;
                return
            end

            A  = V(1:end-1,:);              % segment start points
            B  = V(2:end,:);                % segment end points
            AB = B - A;
            AP = p - A;                     % implicit expansion

            L2 = sum(AB.^2, 2);
            t  = sum(AP.*AB, 2) ./ L2;      % projection parameter
            t(L2 == 0) = 0;                 % degenerate (repeated) vertices
            t  = min(max(t, 0), 1);         % clamp to the segment

            C     = A + t.*AB;              % closest point on each segment
            dseg  = sqrt(sum((p - C).^2, 2));

            [d, idx] = min(dseg);
            cp = C(idx,:);
        end

        function dis = p2lineAs2_single(p, lp1, lp2) %single point lp1 and lp2
             u = lp1 - lp2;
             dis = abs(p*u/norm(u));
        end

        function dis_ar = p2lineAs2_multi(par, lp1ar, lp2ar)
            U = lp1ar-lp2ar;
            Uhat = U ./vecnorm(U, 2, 2);
            dis_ar = abs(sum(V.*Uhat, 2));
        end

        function eccentricity = ecc_fromConvHull(convhull)
            hull_cx = mean(convhull(:, 1), 'all');
            hull_cy = mean(convhull(:, 2), 'all');
            %offset all dots in traces
            x_offseted  = convhull(:, 1) - hull_cx;
            y_offseted = convhull(:, 2) - hull_cy;

            cov_matrix = cov([x_offseted, y_offseted]);
            [~, eigenvalues] = eig(cov_matrix);
            lambda = diag(eigenvalues);
            % Principal axes lengths (proportional to sqrt of eigenvalues)
            maxlambda = max(lambda);
            minlambda = min(lambda);
            a = sqrt(maxlambda);  % semi-major axis
            b = sqrt(minlambda);  % semi-minor axis

            eccentricity = sqrt(1-(b/a)^2);
        end

        function s = renameStructField(s, oldName, newName)
            %RENAMESTRUCTFIELD Rename a field of a struct (or struct array), preserving field order.
            %
            %   S = renameStructField(S, OLDNAME, NEWNAME)

            arguments
                s (:,:) struct
                oldName (1,:) char
                newName (1,:) char
            end

            names = fieldnames(s);
            idx = find(strcmp(names, oldName), 1);

            if isempty(idx)
                error('renameStructField:noSuchField', ...
                    'Field "%s" does not exist.', oldName);
            end
            if ~isvarname(newName)
                error('renameStructField:invalidName', ...
                    '"%s" is not a valid field name.', newName);
            end
            if any(strcmp(names, newName)) && ~strcmp(oldName, newName)
                error('renameStructField:nameCollision', ...
                    'Field "%s" already exists.', newName);
            end

            names{idx} = newName;
            s = cell2struct(struct2cell(s), names, 1);
        end

        function [pk, n] = djPrimaryKey(tbl)
            %DJPRIMARYKEY Names and count of the primary-key attributes of a DataJoint table.
            %
            %   [PK, N] = DJPRIMARYKEY(TBL) returns PK, a 1-by-N cell array of
            %   primary-key attribute names in definition order, and N = numel(PK).
            %
            %   TBL may be:
            %     * a DataJoint relvar or query object (dj.GeneralRelvar subclass), or
            %     * a class name, e.g. 'retina.Cell' (char or string scalar).
            %
            %   The returned key includes attributes inherited through foreign keys,
            %   which is what you want when building a restriction struct.
            %
            %   Example:
            %       [pk, n] = djPrimaryKey('retina.Cell');
            %       key = cell2struct(repmat({[]}, n, 1), pk(:), 1);

            rel = iResolveRelvar(tbl);

            pk = rel.primaryKey;
            if ~iscell(pk)
                pk = cellstr(pk);
            end
            pk = reshape(pk, 1, []);
            n  = numel(pk);
        end

        function upload_analyze_morph(image_id, seg_id, brainRegion, folder, morph_folder)
            arguments
                image_id 
                seg_id 
                brainRegion 
                folder 
                morph_folder = folder;
            end
            scflag = strcmp(brainRegion, 'SCs');
            dlflag = strcmp(brainRegion, 'dLGN');
            if (~scflag) && (~dlflag)
                error('Brain region is not suporrted!\n');
            end
            sln_image.AxonMorphFileV2.insert_new_morphfile(image_id, seg_id, brainRegion, folder);
            if (scflag)
                %TODO add SC annotation uploading
                sln_image.SCsAxonMorph.morph_analyze(image_id, seg_id);
            else
                sln_image.BorderDLGN.load_dlgn_fromFolder(morph_folder, image_id);
                sln_image.DlgnAxonMorph.morph_analyze(image_id, seg_id);
            end
            fprintf('Analysis finished.\n');

        end
        
        function visualize_dlgn_trace(image_id, seg_id)
            key.image_id = image_id;
            border = fetch(sln_image.BorderDLGN & key, '*');

            %key.seg_id = seg_id;
            traces = sln_image.AxonMorphFileV2.get_trace_coords(image_id, seg_id);

            %plotting
            clf;
            hold on;
            plot(border.dlgn_loop(:, 1), border.dlgn_loop(:, 2));
            scatter(traces(:, 1), traces(:, 2), 'filled');
            hold off;
        end
    end
end

function rel = iResolveRelvar(tbl)
% Accept an already-instantiated relvar, or build one from a class name.

    if iIsRelvar(tbl)
        rel = tbl;
        return
    end

    if ~(ischar(tbl) || (isstring(tbl) && isscalar(tbl)))
        error('djPrimaryKey:BadInput', ...
            'TBL must be a DataJoint relvar or a class name; got %s.', class(tbl));
    end

    name = char(tbl);
    if exist(name, 'class') ~= 8
        error('djPrimaryKey:UnknownClass', ...
            'No class named ''%s'' is visible on the MATLAB path.', name);
    end

    rel = feval(name);
    if ~iIsRelvar(rel)
        error('djPrimaryKey:NotATable', ...
            '''%s'' is a class but does not expose a primaryKey property.', name);
    end
end

function tf = iIsRelvar(x)
% True for anything that walks like a DataJoint relvar, regardless of which
% package the base class lives in across DataJoint versions.
    tf = isobject(x) && ismember('primaryKey', properties(x));
end