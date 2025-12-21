classdef PairedSpotsParams < aka.Alias
    properties
        query = aka.BlockParams('PairedSpotField') * proj(aka.EpochParams('PairedSpotField'),'*')
    end
end