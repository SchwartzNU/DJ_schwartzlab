function P = getUniqueEpochParametersSets(protocol_params_all, changing_fields, epoch_ids, excludeParams)

%find all combinations of the changing fields
L = length(excludeParams);
for i=1:L
    ind = strcmp(changing_fields, excludeParams{i});
    changing_fields = changing_fields(~ind);
end

Nepochs = length(protocol_params_all);
subsets = struct;

if isempty(changing_fields)
    P = [];
else    
    %find all combinations of the others
    for f=1:length(changing_fields)
        vals = zeros(Nepochs,1);
        curField = changing_fields{f};
        subsets(f).field = curField;
        for i=1:Nepochs
            vals(i) = protocol_params_all{i}.(curField);
        end
        vals_unique = unique(vals);
        subsets(f).valsU = vals_unique;
        subsets(f).vals = vals;
    end
    
    L = length(subsets);
    for i=1:L
        V{i} = 1:length(subsets(i).valsU);
    end
    allInd = combvec(V{:});
    
    paramSet = struct;
    P = struct;
    z=1;
    for i=1:size(allInd,2)
        paramSet(i).vals = [];
        for j=1:size(allInd,1)
            curVal = subsets(j).valsU(allInd(j,i));
            paramSet(i).vals = [paramSet(i).vals curVal];
            
            %now get the epoch ids that match this
            if j==1
                ind = subsets(j).vals == paramSet(i).vals(j);
            else
                ind = ind & subsets(j).vals == paramSet(i).vals(j);
            end
        end
        if sum(ind)>0
            for f=1:length(subsets)
                P(z).fields{f} = subsets(f).field;
            end
            P(z).ind = find(ind);
            P(z).epoch_ids = epoch_ids(ind);
            P(z).paramVals = paramSet(i).vals;
            z=z+1;
        end
    end 
end
