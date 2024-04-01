function data_struct = collectRadialSpotsDataForCell(cellname, toh5)

if nargin<2
    toh5 = false;
end

results_CA = sln_results.DatasetRadialSpotsCA * sln_cell.CellName & ...
    sprintf('cell_name="%s"', cellname);

fprintf('%d cell-attached dataset results.\n', results_CA.count);

results_CC = sln_results.DatasetRadialSpotsCC * sln_cell.CellName & ...
    sprintf('cell_name="%s"', cellname);

fprintf('%d current clamp dataset results.\n', results_CC.count);

results_VC = sln_results.DatasetRadialSpotsVC * sln_cell.CellName & ...
    sprintf('cell_name="%s"', cellname);

fprintf('%d voltage clamp dataset results.\n', results_VC.count);

data_struct = struct;
if results_CA.exists
    T = sln_results.toMatlabTable(results_CA);    
    for i=1:results_CA.count
        if T.rstar_intensity_spot(i) < 900            
            field_name = 'CA_dim';
        else
            field_name = 'CA_bright';
        end
        data_struct.(['spot_distances_' field_name]) = T.spot_dist{1};
        spikeMatrix = T.spike_count_matrix_mean{i};
        spikeMatrix(spikeMatrix(:,1)==0) = nan;
        data_struct.(['spikes_mean_' field_name]) = nanmean(spikeMatrix,1)';
        data_struct.(['spikes_sem_' field_name]) = nanstd(spikeMatrix,[],1)'./(sqrt(size(spikeMatrix,1)-1));

        data_struct.(['spike_matrix_' field_name]) = spikeMatrix;

    end
end

if results_VC.exists
    T = sln_results.toMatlabTable(results_VC);    
    for i=1:results_VC.count
        if T.rstar_intensity_spot(i) < 900
            field_name = 'VC_dim';
        else
            field_name = 'VC_bright';
        end
        data_struct.(['spot_distances_' field_name]) = T.spot_dist{1};
        peakMatrix = T.peak_matrix_mean{i};
        peakMatrix(peakMatrix(:,1)==0) = nan;
        data_struct.(['peak_current_mean_' field_name]) = nanmean(peakMatrix,1)';
        data_struct.(['peak_current_sem_' field_name]) = nanstd(peakMatrix,[],1)'./(sqrt(size(peakMatrix,1)-1));
        data_struct.(['peak_matrix_' field_name]) = peakMatrix;
    end
end

if results_CC.exists
    T = sln_results.toMatlabTable(results_CC);    
    for i=1:results_CC.count
        if T.rstar_intensity_spot(i) < 900            
            field_name = 'CC_dim';
        else
            field_name = 'CC_bright';
        end
        params_query = proj(results_CC) ...
            * aka.BlockParams('SpotField') * aka.EpochParams('SpotField') ...
            * sln_symphony.DatasetEpoch ...
            * sln_symphony.ExperimentElectrode & ...
            sprintf('dataset_name="%s"', T.dataset_name{i});
        hold_val = unique(fetchn(params_query,'hold'));
        if length(hold_val)>1
            error('More than one holding current value in dataset %s\n', T.dataset_name{i})
            return;
        end
        field_name = sprintf('%s_hold_%d',field_name, hold_val);
        field_name = strrep(field_name,'-','m');
        data_struct.(['spot_distances_' field_name]) = T.spot_dist{1};
        peakMatrix = T.peak_matrix_mean{i};
        peakMatrix(peakMatrix(:,1)==0) = nan;
        data_struct.(['peak_voltage_mean_' field_name]) = nanmean(peakMatrix,1)';
        data_struct.(['peak_voltage_sem_' field_name]) = nanstd(peakMatrix,[],1)'./(sqrt(size(peakMatrix,1)-1));
        data_struct.(['peak_matrix_' field_name]) = peakMatrix;
    end
end

if toh5
    %h5_name = sprintf('%sRadialSpotsData_%s.h5', getenv('h5_folder'), cellname)
    h5_name = sprintf('RadialSpotsData_%s.h5', cellname)
    exportStructToHDF5(data_struct,h5_name,'/');
end

