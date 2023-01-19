classdef PulseParams < aka.Alias
    properties
        query = sln_symphony.ExperimentProtPulseV1bp * sln_symphony.ExperimentProtPulseV1ep;
    end
end