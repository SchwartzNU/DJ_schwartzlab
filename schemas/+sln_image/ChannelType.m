%{
# Content of an image channel
channel_type_id : int unsigned auto_increment
---
channel_content: varchar(64)
%}

classdef ChannelType < dj.Lookup

end