function [] = reloadSpikeData(cell_id, epochRange)
if nargin < 2
    epochRange = [];
end
if isempty(epochRange)
    theseSpikeTrains = sl_mutable.SpikeTrain & sprintf('cell_id="%s"', cell_id);
else
    theseSpikeTrains = sl_mutable.SpikeTrain & sprintf('cell_id="%s"', cell_id) ...
        & sprintf('epoch_number>=%d', epochRange(1)) & sprintf('epoch_number<=%d', epochRange(2)); 
end

if ~theseSpikeTrains.exists
    fprintf('Spike trains not found in database\n');
    return;
end

del(theseSpikeTrains);
populate(sl_mutable.SpikeTrain, sprintf('cell_id="%s"', cell_id));