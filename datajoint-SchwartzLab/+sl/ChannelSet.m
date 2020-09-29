%{
# Color channel map for image
channel_set_id : smallint unsigned auto_increment
---
(channel1_id) -> sl.Channel(channel_id)
(channel2_id) -> sl.Channel(channel_id)
(channel3_id) -> sl.Channel(channel_id)
(channel4_id) -> sl.Channel(channel_id)

%}

classdef ChannelSet < dj.Lookup 
end

%N_channels : tinyint unsigned 
