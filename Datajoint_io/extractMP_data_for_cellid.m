function [] = extractMP_data_for_cellid(cell_unid)

FI_query = sln_results.DatasetMultiPulseFIcurve * sln_cell.Cell * sln_cell.CellName & sprintf('cell_unid=%d',cell_unid);
featureExtract_query = sln_results.DatasetMultiPulsevaryCurrentFeatureExtract * sln_cell.Cell * sln_cell.CellName & sprintf('cell_unid=%d',cell_unid);

s = fetch(FI_query,'*');
traces_struct = fetch(featureExtract_query,'example_traces');
s.example_traces = traces_struct.example_traces;

exportStructToHDF5(s,sprintf('MultiPulseData_%d.h5',cell_unid),['/' s.cell_name])
