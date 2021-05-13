function [] = reloadCellDataFile(cell_id)
%needs to be done by an admin: sl_user account
thisEntry = sl.SymphonyRecordedCell & sprintf('cell_id="%s"', cell_id);
if ~thisEntry.exists
    fprintf('Cell %s not found in database\n', cell_id);    
    return;
end
%delete linked results
sl.UserDB
user_dbs = fetchn(sl.UserDB,'db_name');
N = length(user_dbs);
try
for i=1:N
    key.cell_id = cell_id;
    eval(sprintf('q=%s.EpochResult & key;', user_dbs{i}))
    if~isempty(q)
        del(q);
    end
    eval(sprintf('q=%s.DatasetResult & key;', user_dbs{i}))
    if~isempty(q)
        del(q);
    end
    eval(sprintf('q=%s.CellResult & key;', user_dbs{i}))
    if~isempty(q)
        del(q);
    end    
end
catch
    disp('No results deleted');
end
thisEntry_spikes = sl_mutable.SpikeTrain & sprintf('cell_id="%s"', cell_id);
if thisEntry_spikes.exists
    del(thisEntry_spikes);
end    



del(thisEntry);
populate(sl.SymphonyRecordedCell, sprintf('cell_id="%s"', cell_id));