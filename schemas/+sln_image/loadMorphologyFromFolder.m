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
    if match_count == 0
        fprintf('Error: could not match arborData for folder %s\n', cur_folder);
    else
        matched_cell = sln_cell.RetinalCell * sln_image.RetinalCellImage & match;
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
                key.arbor_density = appdata.arborStats.arborDensity;
                key.bistratified = appdata.arborStats.bistratified;
                if key.bistratified
                    key.polygon_area_lower = appdata.arborStats.polygonArea_lower;
                    key.convexity_index_lower = appdata.arborStats.convexityIndex_lower;
                    key.polygon_area_upper = appdata.arborStats.polygonArea_upper;
                    key.convexity_index_upper = appdata.arborStats.convexityIndex_upper;
                else
                    key.polygon_area = appdata.arborStats.polygonArea;
                    key.convexity_index = appdata.arborStats.convexityIndex;
                end
                disp('Inserting sln_image.RetinalCellMorphology');
                insert(sln_image.RetinalCellMorphology,key);
                disp('Done');
            end
        else %multiple matches found, error
            fprintf('Error arborData in folder %s matched to more than one cell in database\n', cur_folder);
        end
    end
end