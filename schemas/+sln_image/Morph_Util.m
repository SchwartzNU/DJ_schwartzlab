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
    end
end