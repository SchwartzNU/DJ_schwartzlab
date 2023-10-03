classdef RampParams < aka.Alias
    properties
        query = aka.BlockParams('Ramp') * aka.EpochParams('Ramp');
    end
end