classdef Spikes < aka.Alias
    properties
        query = sln_symphony.SpikeTrain;
    end
    
    methods
        function self = Spikes(amp_mode)
            if nargin
                args = {sln_symphony.SymphonyElectrode...
                    & sprintf('amp_mode="%s"',amp_mode)};
            else
                args = {};
            end
            self@aka.Alias(args{:});
        end
    end
end