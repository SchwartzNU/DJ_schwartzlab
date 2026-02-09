function [] = loadMorphologyFromFolder(folder_name)
if nargin<1
    folder_name = uigetdir('','Select folder where images are located');
end
if ~exist(folder_name,'dir')
    error('Please specify a valid folder.');
end
%find all arborData
D = dir([folder_name filesep '**' filesep 'arborData.mat']);
fprintf('%d arborData.mat files found.\n', length(D));
for i=1:length(D)
    file_info = D(i);
    cur_folder = file_info.folder;
    id_match = false;

    D_cell_id = dir([cur_folder filesep 'cell_id_*.txt']);
    if ~isempty(D_cell_id)
        id_part = extractBetween(D_cell_id(1).name, 'id_', '.txt');
        matched_cell = sln_cell.RetinalCell * sln_image.RetinalCellImage & ...
            sprintf('cell_unid=%s',id_part{1});
        id_match = true;
        q = sln_image.RetinalCellImage & sprintf('cell_unid=%s',id_part{1});
        image_id = unique(fetchn(q,'image_id'));
        match_name = fetch1(sln_image.Image & sprintf('image_id=%d',image_id),'image_filename');
        match_count = 1;
    else
        D_tif = dir([cur_folder filesep '*.tif']);
        D_nd2 = dir([cur_folder filesep '*.nd2']);
        D_thisFolderImages = [D_tif; D_nd2];
        match_count = 0;
        for j=1:length(D_thisFolderImages)
            cur_im = D_thisFolderImages(j);
            temp_match = sln_image.Image.get_db_match(cur_im);
            if temp_match.exists %make sure it matches a cell already
                temp_match = temp_match & sln_image.RetinalCellImage;
            end
            if temp_match.exists
                match_count = match_count+1;
                match = temp_match;
                match_name = cur_im.name;
            end
        end
    end
    if match_count == 0
        fprintf('Error: could not match arborData for folder %s\n', cur_folder);
    else
        if ~id_match
            matched_cell = sln_cell.RetinalCell * sln_image.RetinalCellImage & match;
        end
        if matched_cell.count == 1
            %check if entry is already there
            morph_match = sln_image.RetinalCellMorphology & sprintf('cell_unid=%d',fetch1(matched_cell,'cell_unid'));
            if morph_match.exists
                fprintf('Morphology data for cell %s, cell_id %d, already in database. Skipping.\n', match_name, fetch1(matched_cell,'cell_unid'));
            else
                fprintf('Matched arborData for image %s to cell %d\n', match_name, fetch1(matched_cell,'cell_unid'));
                load([cur_folder filesep 'arborData.mat'],'appdata');
                key = struct;
                key.cell_unid = fetch1(matched_cell,'cell_unid');
                key.nodes_flattened = appdata.nodes_flattened;
                key.edges_flattened = appdata.edges_flattened;
                key.radii_flattened = appdata.radii_flattened;
                key.lower_surface_z = appdata.lower_surface_z;
                key.upper_surface_z = appdata.upper_surface_z;
                key.strat_x = appdata.strat_x;
                key.strat_density = appdata.strat_density;
                key.strat_y_norm = appdata.strat_y_norm;
                key.branch_lengths = appdata.arborStats.branchLen;
                key.branch_angles = appdata.arborStats.branchAngle;
                key.branch_z_range = appdata.arborStats.branchRangeZ;
                key.branch_tortuosity = appdata.arborStats.branchTortuosity;
                key.n_branches = appdata.arborStats.Nbranches;
                key.arbor_length = appdata.arborStats.totalLen;
                key.arbor_complexity = appdata.arborStats.arborComplexity;
                key.bistratified = appdata.arborStats.bistratified;
                if key.bistratified
                    key.polygon_area_lower = appdata.arborStats.polygonArea_lower;
                    key.convexity_index_lower = appdata.arborStats.convexityIndex_lower;
                    key.polygon_area_upper = appdata.arborStats.polygonArea_upper;
                    key.convexity_index_upper = appdata.arborStats.convexityIndex_upper;
                    key.arbor_density_upper = appdata.arborStats.arborDensity_upper;
                    key.arbor_density_lower = appdata.arborStats.arborDensity_lower;
                else
                    key.polygon_area = appdata.arborStats.polygonArea;
                    key.convexity_index = appdata.arborStats.convexityIndex;
                    key.arbor_density = appdata.arborStats.arborDensity;
                end
                disp('Inserting sln_image.RetinalCellMorphology');
                insert(sln_image.RetinalCellMorphology,key);
                disp('Done');
            end
        else %multiple matches found, error
            fprintf('Warning: arborData in folder %s matched to more than one cell in database\n', cur_folder);
            cell_ids = fetch(matched_cell, 'cell_unid');
            fprintf('Those cells are both/all linked to the same image, please chose one after the promot appears.\n');
            for k = 1:numel(cell_ids)
                fprintf('%d\n', cell_ids(k).cell_unid);
            end
            fprintf('Hint: to terminate this function press ctrl+C\n');
            inputconfirmed = false;
            while ~inputconfirmed
                input1 = input('Type the cell id: ');
                
                if (isnumeric(input1))
                    if(ismember(input1, [cell_ids.cell_unid]))
                        input2 = input('Confirm? press Y. If not, press any other key\n', "s");
                        if (strcmpi(input2, 'y'))
                            inputconfirmed = true;
                            break;
                        else
                            frpintf('Cell id not confirmed... redo\n');
                            continue;
                        end
                    else
                        fprintf('Cell id is not in the list.\n');
                        continue;
                    end
                else
                    fprintf('Input is not a number\n');
                end
                
            end
            
            %upload processs... 
            fprintf('Matched arborData for image %s to cell %d\n', match_name, input1);
            newq = sprintf('cell_unid = %d', input1);
            %sanity check: has the morphology been uploaded before?
            morph = fetch(sln_image.RetinalCellMorphology & newq);
            if (numel(morph)~=0)
                fprintf('Data already exist, existing the function now\n');
                return
            end

            matched_cell = sln_cell.RetinalCell * sln_image.RetinalCellImage & newq;
            load([cur_folder filesep 'arborData.mat'],'appdata');
            key = struct;
            key.cell_unid = fetch1(matched_cell,'cell_unid');
            key.nodes_flattened = appdata.nodes_flattened;
            key.edges_flattened = appdata.edges_flattened;
            key.radii_flattened = appdata.radii_flattened;
            key.lower_surface_z = appdata.lower_surface_z;
            key.upper_surface_z = appdata.upper_surface_z;
            key.strat_x = appdata.strat_x;
            key.strat_density = appdata.strat_density;
            key.strat_y_norm = appdata.strat_y_norm;
            key.branch_lengths = appdata.arborStats.branchLen;
            key.branch_angles = appdata.arborStats.branchAngle;
            key.branch_z_range = appdata.arborStats.branchRangeZ;
            key.branch_tortuosity = appdata.arborStats.branchTortuosity;
            key.n_branches = appdata.arborStats.Nbranches;
            key.arbor_length = appdata.arborStats.totalLen;
            key.arbor_complexity = appdata.arborStats.arborComplexity;
            key.bistratified = appdata.arborStats.bistratified;
            if key.bistratified
                key.polygon_area_lower = appdata.arborStats.polygonArea_lower;
                key.convexity_index_lower = appdata.arborStats.convexityIndex_lower;
                key.polygon_area_upper = appdata.arborStats.polygonArea_upper;
                key.convexity_index_upper = appdata.arborStats.convexityIndex_upper;
                key.arbor_density_upper = appdata.arborStats.arborDensity_upper;
                key.arbor_density_lower = appdata.arborStats.arborDensity_lower;
            else
                key.polygon_area = appdata.arborStats.polygonArea;
                key.convexity_index = appdata.arborStats.convexityIndex;
                key.arbor_density = appdata.arborStats.arborDensity;
            end
            disp('Inserting sln_image.RetinalCellMorphology');
            insert(sln_image.RetinalCellMorphology,key);
            disp('Done');

        end
    end
end