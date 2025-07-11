%% setup
prots = ["NaturalMovingObjectAndFlash"];
exp_file = "071125B";
out_file = "D:\071125B_results.mat";

%%
clear results;
co = sln_symphony.ExperimentCell & sprintf('file_name="%s"',exp_file);
cells = fetchn(co, 'source_id');

i=1;
for c = cells'
    for prot = prots
        query = aka.EpochParams(prot) * aka.BlockParams(prot) * sln_symphony.ExperimentProjectorSettings *...
            sln_symphony.DatasetEpoch * sln_symphony.ExperimentChannel * sln_symphony.SpikeTrain * sln_cell.AssignType.current * sln_cell.Cell * ...
            (co & sprintf('source_id=%d', c))* proj(sln_symphony.ExperimentRetina, 'source_id->retina_id', 'side','orientation');
            %* sln_symphony.Experiment * sln_symphony.Calibration; %for mpp
        query = proj(query,'IF(`orientation` like "ventral up",1,0) -> vu', 'IF(`side` like "left",1,0) -> le', '*');
        query = proj(query, 'vu xor le->flip', '*');
        query = proj(query, '(-2 * flip  + 1) * x -> NT', '*');
        
        results(i).(prot) = fetch(query, '*');
        
        if strcmp(prot,'NaturalMovingObjectAndFlash')
            %v2 -- inefficient since we're repeating seeds
            for j = 1: length(results(i).(prot))
                obj = results(i).(prot)(j);
                Nsamp = obj.pre_frames + obj.stim_frames + obj.tail_frames + 1;
                total_time = Nsamp * 1/60;
                t_hex = (obj.pre_frames + obj.stim_frames) * 1/60;
    
                if strcmp(obj.cur_motion_type, 'natural')
                    [x,y] = sa_labs.util.BMARGSMv2(obj.tau, obj.sigma, obj.tauz,obj.sigmaz, 1/60, ...
                        total_time,t_hex ,obj.mosaic_spacing/sqrt(3)+obj.leeway,obj.tburn,obj.motion_seed);
                    
                elseif strcmp(obj.cur_motion_type, 'control')
                    [~,~,~,~,~,~,x,y,~,~] ...
                            = sa_labs.util.BMARGSMv2(obj.tau, obj.sigma, obj.tauz,obj.sigmaz, 1/60, ...
                        total_time,t_hex ,obj.mosaic_spacing/sqrt(3)+obj.leeway,obj.tburn,obj.motion_seed);
                elseif strcmp(obj.cur_motion_type, 'flash')
                    [~,~,~,~,~,~,~,~,x,y] = ...
                            sa_labs.util.BMARGSMv2(obj.tau, obj.sigma, obj.tauz,obj.sigmaz, 1/60, ...
                        total_time,t_hex ,obj.mosaic_spacing/sqrt(3)+obj.leeway,obj.tburn,obj.motion_seed);
                end
                
                results(i).(prot)(j).trans_x = results(i).(prot)(j).cx;
                results(i).(prot)(j).trans_y = results(i).(prot)(j).cy;

                results(i).(prot)(j).cx = results(i).(prot)(j).cx + x(1:end-1);
                results(i).(prot)(j).cy = results(i).(prot)(j).cy + y(1:end-1);
            end


        end
    end
    i = i+1;
end
%%
save(out_file,'results', '-v7.3');

