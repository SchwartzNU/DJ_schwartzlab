function add_reagent(keys, reagent_type) 
stain_reagent_fields = ...
    {'suggested_dilution', ...
    'reagent_name', ...
    'catalog_name', ...
    'vendor_name', ...
    'catalog_number', ...
    'reagent_info', ...
    'storage_temp', ...
    };
reagent_id = zeros(length(keys),1);

for i=1:length(keys)
    key = keys(i);
    for f=1:length(stain_reagent_fields)
        thisField = stain_reagent_fields{f};
        if isfield(key, thisField)
            thisValue = key.(thisField);
            if ~isempty(thisValue)
                key_r.(thisField) = thisValue;
            end
            key = rmfield(key,thisField);
        end
    end

    %remove empty fields
    fields = fieldnames(key);
    for f=1:length(fields)
        if isempty(key.(fields{f}))
            key = rmfield(key,fields{f});
        end
    end

    %first check if this reagent already exists
%    sub_table = feval(sprintf('sln_tissue.%s',reagent_type));
%     key_r
%     key
%     keyboard;
    q = sln_tissue.StainReagent & sprintf('reagent_name="%s"', key_r.reagent_name);
    if q.exists
        disp('already exists');
%        keyboard;
        %do nothing
    else %add it
        C = dj.conn;
        C.startTransaction;
        try
            %key_r
            disp('insert try')
            insert(sln_tissue.StainReagent,key_r);
            reagent_id(i) = fetch1(sln_tissue.StainReagent, 'reagent_id', 'ORDER BY reagent_id DESC LIMIT 1');
            key.reagent_id = reagent_id(i);
            %key
            insert(feval(sprintf('sln_tissue.%s',reagent_type)), key);
            disp('insert success')
            C.commitTransaction;
        catch ME            
            C.cancelTransaction;
            rethrow(ME)
        end
    end
end