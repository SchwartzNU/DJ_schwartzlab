classdef Alias < dj.internal.GeneralRelvar
    properties (Abstract)
        query;
    end
    methods
        function self = Alias(projection, varargin)
            if ~nargin || isempty(projection)
                projection = {'*'};
            elseif ~isa(projection,'cell')
                projection = {projection};
            end
            self = self@dj.internal.GeneralRelvar();
            self.init('proj',vertcat({self.query},projection{:}),varargin);
        end
    end
end

