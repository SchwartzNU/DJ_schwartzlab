classdef SMSparams < aka.Alias
    properties
        query = proj(aka.EpochParams('SpotsMultiSize'),'cur_spot_size->block_cur_spot_size','protocol_version->version','*') * aka.EpochParams('SpotsMultiSize');
    end
end