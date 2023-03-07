classdef MultiPulseParams < aka.Alias
    properties
        query = aka.BlockParams('MultiPulse') * aka.EpochParams('MultiPulse');
    end
end