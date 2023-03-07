classdef ContrastResponseParams < aka.Alias
    properties
        query = aka.BlockParams('ContrastResponse') * aka.EpochParams('ContrastResponse');
    end
end