function R = spikesInIntervals(epoch, pipeline, P)
%results spikes in specific intervals relative to Pre, Stim and Post times
%Parmeters:
%intervals: array where each row is an interval in ms
%for example, [0, 100; 400 500] for the intervals from 0-100 ms and 400-500 ms
%if the last value of an interval is Inf, it ends at the next interval (or end of the epoch for a 'post' type).
%interval_reference: cell array with the same number of entries as rows in 'intervals'
%each containing one of the following 'pre', 'stim', 'post'. This parameters sets the reference time
%that equals zero for the corresponding interval

R = []; %will be struct. error if isempty
sp_train = sl_mutable.SpikeTrain & epoch;
ep_struct = fetch(epoch,'*');
N_trains = sp_train.count;
if N_trains == 0
    disp(['spikesInIntervals failed to get spikes: ' ep_struct.cell_id ': epoch ' num2str(ep_struct.epoch_number)]);
    return;
elseif N_trains > 1
    disp(['spikesInIntervals duplicate spike train: ' ep_struct.cell_id ': epoch ' num2str(ep_struct.epoch_number)]);
    return;
end

sp = fetch1(sp_train, 'sp');

%get pre, stim, and tail times in ms
try 
    preTime = ep_struct.protocol_params.preTime;
    stimTime = ep_struct.protocol_params.stimTime;
    tailTime = ep_struct.protocol_params.tailTime;
    sample_rate = ep_struct.sample_rate;
catch
    fprintf('spikesInIntervals warning for cell %s, epoch %d. Unable to get preTime, stimTime, or tailTime or sampleRate.\n', ...
        ep_struct.cell_id, ep_struct.epoch_number);   
    %defaults
    preTime = 0;
    tailTime = 0;
    stimTime = ep_struct.protocol_params.stimTime;
    sample_rate = 1E4;
end

sp_rel_to_pre = 1E3 * sp / sample_rate;
sp_rel_to_stim = sp_rel_to_pre - preTime;
sp_rel_to_post = sp_rel_to_stim - stimTime;

N = size(P.intervals,1);
resultNames = cell(N,1);

if length(P.interval_reference) ~= N
    disp('Error in spikesInIntervals: rows in interval parameter must match # of elements in interval_reference parameter'); 
    return;
end

for i=1:N
    curInterval = P.intervals(i,:);
    curRef = P.interval_reference{i};
    curInterval_str = num2str(curInterval);
    curInterval_str = regexprep(curInterval_str, ' +', 'to');
    curInterval_str = strrep(curInterval_str, '-', 'neg');
    curInterval_str = strrep(curInterval_str, '.', 'pt');
    resultNames{i} = [curRef '_' curInterval_str];
    switch curRef
        case 'pre'
            if isinf(curInterval(2))
                curInterval(2) = preTime;
                R.([resultNames{i} '_dur']) = range(curInterval)/1E3; %duration in s 
            end
            if curInterval(1)<0 || curInterval(2) > preTime
                disp('Warning in spikesInIntervals: interval exeeds part of epoch. Setting to NaN.');
                R.(resultNames{i}) = NaN;
            else
                R.(resultNames{i}) = length(find(sp_rel_to_pre>=curInterval(1) & sp_rel_to_pre<curInterval(2)));
            end
        case 'stim'
            if isinf(curInterval(2))
                curInterval(2) = stimTime;
                 R.([resultNames{i} '_dur']) = range(curInterval)/1E3; %duration in s 
            end
            if -curInterval(1)>preTime || curInterval(2) > stimTime
                disp('Warning in spikesInIntervals: interval exeeds part of epoch. Setting to NaN.');
                R.(resultNames{i}) = NaN;
            else
             R.(resultNames{i}) = length(find(sp_rel_to_stim>=curInterval(1) & sp_rel_to_stim<curInterval(2)));
            end
        case 'post'
            if isinf(curInterval(2))
                curInterval(2) = tailTime;
                 R.([resultNames{i} '_dur']) = range(curInterval)/1E3; %duration in s 
            end
            if -curInterval(1)>preTime+stimTime || curInterval(2) > tailTime
                disp('Warning in spikesInIntervals: interval exeeds part of epoch. Setting to NaN.');
                R.(resultNames{i}) = NaN;
            else
                R.(resultNames{i}) = length(find(sp_rel_to_post>=curInterval(1) & sp_rel_to_post<curInterval(2)));
            end
        otherwise
            fprintf('Error in spikesInIntervals: unrecognized interval_reference %s\n', curRef);
            return;
    end
end



