function [] = extract_allPositions_SMS
allTypes = unique(fetchn(sl_mutable.CurrentCellType & 'cell_class="RGC"', 'cell_type'));
allTypes = setdiff(allTypes,'unknown');

for i=1:length(allTypes)
    q = sl.CellType & sprintf('name_full="%s"', allTypes{i});
    shortName = fetch1(q, 'name_for_var')
    fname = ['Positions_SMSdata_' shortName];
    q = sl.MeasuredRetinalCell * sl.SymphonyRecordedCell * sl_greg.DatasetResult * sl_mutable.CurrentCellType & ...
        sprintf('cell_type="%s"', allTypes{i}) & 'pipeline_name="typology_SMS_CA"';
    extract_cellPositionsForQuery(q, fname);
end