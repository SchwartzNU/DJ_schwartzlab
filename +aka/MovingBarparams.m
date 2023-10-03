classdef MovingBarparams < aka.Alias
    properties
        query = aka.BlockParams('MovingBar') * aka.EpochParams('MovingBar');
    end
end