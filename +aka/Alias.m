classdef Alias < dj.internal.GeneralRelvar
    properties (Abstract)
        query;
    end
    methods
        function self = Alias(varargin)
            self = self@dj.internal.GeneralRelvar();
            self.init('proj',{self.query,'*'},varargin);
        end
    end
end

