classdef SMSparams < aka.Alias
    properties
        query = aka.BlockParams('SpotsMultiSize') * aka.EpochParams('SpotsMultiSize');
    end
end