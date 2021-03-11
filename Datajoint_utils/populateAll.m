function [] = populateAll()
    parpopulate(sl.SymphonyRecordedCell);

    f = fetch(sl.Epoch & "recording_mode='Cell attached'");
    [f.channel] = deal(1);

    f2 = fetch(sl_mutable.SpikeTrainMissing);
    for n=1:numel(f2)
        f   (arrayfun(@(x) isequaln(x, f2(n)), f)) = [];
    end


    parpopulate((sl_mutable.SpikeTrain & (sl.Epoch & "recording_mode='Cell attached'") & "channel=1") - sl_mutable.SpikeTrainMissing().proj());
    parpopulate((sl_mutable.SpikeTrain & (sl.Epoch & "recording2_mode='Cell attached'") & "channel=2") - sl_mutable.SpikeTrainMissing().proj())
end