classdef FlashedBarParams < aka.Alias
    properties
        query = aka.BlockParams('FlashedBar') * aka.EpochParams('FlashedBar');
    end
end