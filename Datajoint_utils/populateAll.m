function [] = populateAll()
    parpopulate(sl.SymphonyRecordedCell);
    parpopulate(sl_mutable.SpikeTrain & (sl.Epoch & "recording_mode='Cell attached'") & "channel=1" - sl_mutable.SpikeTrainMissing);
    parpopulate(sl_mutable.SpikeTrain & (sl.Epoch & "recording2_mode='Cell attached'") & "channel=2" - sl_mutable.SpikeTrainMissing)
end