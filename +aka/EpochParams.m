classdef EpochParams < dj.internal.GeneralRelvar
    
    properties(SetAccess=private)
        tableHeader
        fullTableName
        schema = sln_symphony.getSchema()
    end
    
    methods
        function self = EpochParams(protocolBaseName)    
            
            %% get the protocol function handles
            cx = sln_symphony.getSchema().classNames;
            bre = sprintf('sln_symphony.ExperimentProt%sV\\d+ep',protocolBaseName);
            ci = ~cellfun(@isempty, regexp(cx,bre));            
            ub = cellfun(@feval, cx(ci), 'uniformoutput', 0);
            
            %% assemble the header
            fields = cellfun(@(x) x.nonKeyFields, ub, 'uniformoutput', 0);
            fields = unique(horzcat(fields{:}));
            
            attrs = cellfun(@(x) x.header.attributes, ub, 'UniformOutput', false);
            attrs = vertcat(attrs{:});
            fattrs = cell2struct(cell(length(fieldnames(attrs)),0), fieldnames(attrs));
            
            for i = 1:length(fields)
                fattrs(i).name = fields{i};
                fattrs(i).isnullable = true;
                fattrs(i).default = '';
                fattrs(i).iskey = false;
                fattrs(i).comment = '';
                fattrs(i).isautoincrement = false;
                fattrs(i).database = 'sln_symphony';
                fattrs(i).alias = '';
                fattrs(i).sqlComment = '';
                fattrs(i).isAttachment = false;
                fattrs(i).isFilepath = false;
                fattrs(i).isUuid = false;
                fattrs(i).isBlob = false;
                fattrs(i).isExternal = false;
                fattrs(i).store = [];
                
                fi = strcmp({attrs(:).name},fields{i});
                
                %only certain field types are valid, at least for now
                if any([attrs(fi).isUuid]) || any([attrs(fi).isExternal]) || any([attrs(fi).isFilepath]) ...
                        || any([attrs(fi).isAttachment]) || any([attrs(fi).store])
                    error('Don''t know how to merge tables');
                end
                
                % %why no blobs?
                % if any([attrs(fi).isUuid]) || any([attrs(fi).isFilepath]) ...
                %         || any([attrs(fi).isAttachment])
                %     error('Don''t know how to merge tables');
                % end
                
                stype = {attrs(fi).sqlType};
                utype = unique(stype);
                
                if length(utype) == 1
                    % all the tables that use this field have the same type
                    fattrs(i).type = attrs(find(fi,1)).type;
                    fattrs(i).sqlType = attrs(find(fi,1)).sqlType;
                    fattrs(i).isNumeric = attrs(find(fi,1)).isNumeric;
                    fattrs(i).isString = attrs(find(fi,1)).isString;
                    fattrs(i).isBlob = attrs(find(fi,1)).isBlob;
                else
                    % there are different types for this field in the table
                    % list
                    
                    % the MySQL engine should combine the types, but
                    % figuring out the resultant type is not trivial, so
                    % for now we'll just call it unknown
                    
                    % see https://dev.mysql.com/doc/refman/8.0/en/type-conversion.html
                    
                    fattrs(i).type = 'unknown';
                    fattrs(i).sqlType = 'unknown';
                    
                    %these properties are required by DataJoint
                    fattrs(i).isNumeric = true;
                    fattrs(i).isString = false;
                    
                    % MySQL organizes the types into a few classes
                    tclass = cell(size(utype));
                    for j = 1:numel(utype)
                        jutype = utype{j};
                        if contains(jutype, 'enum')
                        elseif contains(jutype, 'unsigned')
                            tclass{j} = 'uint';
                        elseif contains(jutype, 'int')
                            tclass{j} = 'int';
                        elseif contains(jutype, 'decimal') || contains(jutype, 'numeric') ||...
                                contains(jutype, 'float') || contains(jutype, 'double')
                            tclass{j} = 'num';
                        elseif contains(jutype, 'char') || contains(jutype, 'enum')
                            tclass{j} = 'str';
                            re = regexp(jutype, 'char(\d*)', 'tokens');
                            if ~isempty(re)
                                mostChars = max(mostChars, str2double(re{1}{1}));
                            end
                        elseif contains(jutype, 'date') || contains(jutype, 'time')
                            tclass{j} = 'datetime';
                        elseif contains(jutype, 'blob')
                            tclass{j} = jutype;
                        else
                            error('Don''t know how to merge tables');
                        end
                    end
                    
                    % for the allowed types, only a few cases where the
                    % output is not numeric
                    if all(strcmp(tclass,'str')) || all(strcmp(tclass,'datetime'))
                        fattrs(i).isNumeric = false;
                        fattrs(i).isString = true;
                    elseif all(strcmp(tclass,'blob'))
                        fattrs(i).isNumeric = false;
                        
                    end
                    
                end
            end
            
            % we will carry forward the primary key, since these are
            % enforced by the Protocol superclass
            fattrs = vertcat(ub{1}.header.attributes([ub{1}.header.attributes(:).iskey]), fattrs');
            self.tableHeader = dj.internal.Header.initFromAttributes(fattrs, protocolBaseName, protocolBaseName);            
            %% assemble the sql
            sql = cell(size(ub));
            for i = 1:length(ub)
                nkf = fields;%ub{i}.nonKeyFields;
                hasField = ismember(nkf, ub{i}.nonKeyFields);%, fields);
                nkf(hasField) = cellfun(@(s) sprintf('`%s`',s), nkf(hasField), 'uni', 0);nkf(~hasField) = cellfun(@(s) sprintf('NULL AS `%s`',s), nkf(~hasField), 'uni', 0);
                if isempty(nkf)
                    sql{i} = sprintf('(SELECT `file_name`,`source_id`,`epoch_group_id`,`epoch_block_id`,`epoch_id` FROM %s)', ub{i}.sql);%, aliasCount);
                
                else
                    sql{i} = sprintf('(SELECT `file_name`,`source_id`,`epoch_group_id`,`epoch_block_id`,`epoch_id`,%s FROM %s)', strjoin(nkf,','), ub{i}.sql);%, aliasCount);
                end
            end
            
            self.fullTableName = sprintf('(%s) AS `ep%s`', strjoin(sql,' UNION '), protocolBaseName);
            
            self.init('table', {self});
            
        end
    end
end

