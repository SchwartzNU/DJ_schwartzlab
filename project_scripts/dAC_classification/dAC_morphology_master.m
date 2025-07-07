%% dAC_morphology_master
%run a query to get everything we want (minus the raw images to save time and space)
q = sln_image.RetinalCellMorphology * ...
    sln_image.RetinalCellImage * ...
    sln_symphony.ExperimentCell * ...
    proj(sln_image.Image,'x_scale','y_scale','z_scale','width','height','n_channels','n_slices','zoom_factor') * ...
    sln_cell.Cell * ...
    sln_cell.CellName * ...
    proj(sln_cell.AssignType.current, 'user_name->user_who_named', '*') * ...
    sln_symphony.UserParamCellDacDataset & 'dac_dataset="T"';

%make query into a MATLAB table
T = sln_results.toMatlabTable(q);

%get unique cells
[c, ind] = unique(T.cell_unid);
fprintf('%d images of %d cells.\n', height(T), length(ind));

%find duplicates
duplicate_indices = setdiff(1:height(T), ind);
L = length(duplicate_indices);
if L>0
    fprintf('%d cells found with duplicate images:\n', L)
    for i=1:L
        fprintf('\t%s\n',T.cell_name{duplicate_indices(i)});
    end
end

%grab each unique type and write its results into an hdf5 file
%hierarchy is type then cell_name
[types, ia, ic] = unique(T.cell_type);
for i=1:length(types)
    fprintf('Collecting data for %s. N=%d.\n', types{i}, sum(ic==i));
    Tpart = T(ic==i,:);
    s = table2struct(Tpart);
    for j=1:length(s)
        exportStructToHDF5(s(j),'dAC_morphology_master.h5',['/' types{i} '/c' s(j).cell_name]);
    end
end