%{
# Spike train corresponding to a single channel in a Symphony epoch
-> sl_zach.SymphonyEpochChannel
---
count: int unsigned # the spike count
spikes = NULL: mediumblob
# for spikes represented as uint32,
# this allows up to 524288 spikes per epoch, or
# ~8min of spikes at 1kHz firing rate for a 10kHz recording.
# uint32 allows a ~5day epoch at 10kHz sample rate so long
# as the total number of spikes is <= 524288 (~1.2Hz average
# for a 5 day epoch)
%}
classdef SymphonySpikeTrain < dj.Part
  properties(SetAccess=protected)
    master = sl_zach.Symphony;
  end

end