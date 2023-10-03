%{
# TemporarySpikeTrainAnalysis
-> sln_symphony.SpikeTrain
---
number_of_spikes_before_stimulus : int unsigned #comment

%}
classdef XinsTemporaryAnalysis < dj.Computed
        methods(Access=protected)
            function makeTuples(self,key) % key will have the same data as fetch(sln_symphony.SpikeTrain)
                % get the spike times
                spike_indices = fetch1(sln_symphony.SpikeTrain & key, 'spike_indices');
                
                % compare them to the preTime property
                protocol_name = fetch1(sln_symphony.ExperimentEpochBlock & key, 'protocol_name');
                
                block_parameters_table = feval(['sln_symphony.ExperimentProtocol',protocol_name,'V1BlockParameters']);
                
                pre_time = fetchn(block_parameters_table & key, 'pre_time');
                
                % add the number in the baseline to the key
                sample_rate = fetch1(sln_symphony.ExperimentChannel & key,'sample_rate');
                
                key.number_of_spikes_before_stimulus = nnz(spike_indices < (pre_time * 1e-3 * sample_rate));
                   
                %insert into the database
                self.insert(key);                
            end
        end
end