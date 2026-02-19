%{
#Retina as tissue
-> sln_tissue.Retina
---
folder : varchar(512) #folder where reconstruction is stored
cell_ids: blob@raw #the unid of cells in this reconstruction
spherical: blob@raw #coordinates in sperical
reproj:blob@raw #reprojected coordinates
%}

classdef RetinaRecon < dj.Manual
methods (Static)
    function [x,y] = retistruct_azimuth(lambda, phi, side)
        %this is a strange 'azimuth equal distance projection' from retistruct R code, very different from the standard formula
        %potentially the retistruct coordinate systems is rotated 90 degree to the equator thus skip the trouble of calculating scaleing function
        rho = pi/2+phi;
        x = rho.*cos(lambda);
        if (strcmp(side, 'Right'))
            fprintf('Flipping the x coordinates for right eye...\n');
            x = -x;
        else
            fprintf('uploading left eye...\n');
        end
        y = rho.*sin(lambda);
    end

    function upload_retina_recon(folder, animalid, cell_idlist, lambda, phi, side, reproj_arr)
        %sph_arr is an n*2 array, first column is the lambda of retistruct reconstruction number,  
        %second column is the phi of reconstruction result. 
        arguments
            folder 
            animalid
            cell_idlist 
            lambda
            phi
            side = 'Left'
            reproj_arr = nan
        end
        try
            key.animal_id = animalid;
            result = fetch(sln_tissue.Retina & key, 'tissue_id', 'side');
            key.tissue_id = result.tissue_id;
            key.side = result.side;

            %check if cells all exists....
            fprintf('Checking input cell ids....\n');
            for i=1:numel(cell_idlist)
                query = {};
                query.cell_unid = cell_idlist(i);
                result = fetch(sln_cell.Cell & query, 'animal_id');
                if (animalid ~= result.animal_id)
                    error('The cell %d does not belong to animal %d! please check again.\n', cell_idlist(i), animalid);
                end
            end
            key.cell_ids = cell_idlist;
            fprintf('Checking cell_unid finished, no error found.\n');
            
            key.folder = convertStringsToChars(folder);
            key.spherical = [lambda, phi];
            if (isnan(reproj_arr))
                [x,y] = sln_tissue.RetinaRecon.retistruct_azimuth(lambda, phi, side);
            end
            reproj_arr = zeros(numel(lambda), 2);
            reproj_arr(:, 1) = x;
            reproj_arr(:, 2) = y;
            key.reproj = reproj_arr;

            C = dj.conn;
            C.startTransaction;
            insert(sln_tissue.RetinaRecon, key);
            C.commitTransaction;
            fprintf('Retina reconstruction inserted, tissue_id: %d\n', key.tissue_id);
        catch ME
            fprintf('Inserting failed. Please refer to the error message.\n');
            rethrow(ME);
        end

    end
end
end