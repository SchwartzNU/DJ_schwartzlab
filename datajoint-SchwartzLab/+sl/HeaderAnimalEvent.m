%
% NOT a DJ table... an override for the DJ header for AnimalEvents
%
classdef HeaderAnimalEvent < handle
    
    properties
        headers
        computedTypeString = '<sql_computed>'
        info
        attributes
        names
        primaryKey
        dependentFields
        blobNames
        notBlobs
        eventType
    end
    
    %ae.compile needs to return a header of this type...
    %same with join, union...
    %.sql needs to consider union
    
    methods
        function self = HeaderAnimalEvent(header, className)
            if ~nargin
                return
            end
            self.attributes = header.attributes;
            self.headers = header;
            
            if nargin > 1
                self.eventType = erase(className,'sl.AnimalEvent');
            end
            
%             if nargin > 2
%                 self.per = per;
%             end
        end
        
        function sql = enclose(hdr, sql_, varargin)
            %a general function for enclosing sql operations
            h = hdr.sql;
            
            if isa(sql_,'cell') %we're unioning
                sql = string(join(cellfun(@(x,y) sprintf('SELECT %s FROM %s',x,y), h, sql_(1:2), 'uniformoutput',false), ' UNION '));
                
                %fix h so that it's no longer a cell and strip the aliases
                h = cellfun(@(x) regexp(x,'`(\w+)`','match'), strsplit(h{1}, ','), 'UniformOutput', false);
                h = join(horzcat(h{:}), ',');
                h = h{:};
                
                if length(sql_)>2
                   sql = string(join(sql,sql_(3:end),' '));
                end
            else
                sql = sprintf('SELECT %s FROM %s', h, sql_);
            end
            
            if nargin>3 && isa(varargin{2}, 'struct')
                %we're doing a limit by group operation
                per = varargin{2};
                if ~isa(varargin{1},'char')
                    sql = sprintf('SELECT %s FROM ( SELECT %s,RANK() OVER (PARTITION BY %s ORDER BY %s) AS rnk FROM (%s) AS `$a%x`) AS `$a%x` WHERE rnk <= %s',...
                        h, h, per.selector, per.orderby, sql, varargin{1}+1, varargin{1}+2, per.limit...
                        );
                else
                    sql = sprintf('SELECT %s FROM ( SELECT %s,RANK() OVER (PARTITION BY %s ORDER BY %s) AS rnk FROM (%s) AS grouplimitA) AS grouplimitB WHERE rnk <= %s',...
                        h, h, per.selector, per.orderby, sql, per.limit...
                        );
                end
                
                
            end
            
            if nargin>2 && ~isempty(varargin{1})
                if isa(varargin{1},'char') %we're dealing with a limit operation...
                    sql = sprintf('(%s)%s', sql, varargin{1});
                else %we're aliasing
                    if isinf(varargin{1})
                        sql = sprintf('(%s) AS final', sql);
                    else
                        sql = sprintf('(%s) AS `$a%x`', sql, varargin{1});
                    end
                end
            end
            
            
            if nargin>4 && strcmp(varargin{end},'count')
                sql = sprintf('SELECT count(*) as n FROM (%s) as counting', sql);
            end
            %aliasCount and limit are mutually exclusive
            
            %output: sql = sprintf('(SELECT %s FROM %s) AS `$a%x`', header.sql, sql, aliasCount);
            % or sql = sprintf('(SELECT %s FROM %s)%s ', header.sql, sql, limit);
            
            % but if isa(hdr.headers,'cell') && strcmp(hdr.headers{3},'union')
            % then sql = sprintf('(SELECT %s FROM %s UNION SELECT %s from FROM %s)%s ', header.sql, sql, limit);
        end
        
        function sql = sql(self)
            %here is where we want to override the default
            
            % make an SQL list of attributes for header
            
            if isa(self.headers,'cell') && strcmp(self.headers{3},'union')
                isUnion = true;
                sql = {'', ''};
            else
                isUnion = false;
                sql = {''};
            end
            
            assert(~isempty(self.attributes))
            for i = 1:length(self.attributes)
                for j=1:1+isUnion
                    if strcmp(self.attributes(i).type, 'fake') && ~isempty(self.headers{j}.eventType)
%                         if isempty(self.headers{j}.eventType)
%                             sql{j} = sprintf('%s,`%s`', sql{j}, self.attributes(i).name);
%                         else
                            sql{j} = sprintf('%s,''%s'' as `%s`', sql{j}, self.headers{j}.eventType, self.attributes(i).name);
%                         end
                    elseif isUnion && ~ismember(self.attributes(i).name, self.headers{j}.names)
                        sql{j} = sprintf('%s,Null as `%s`', sql{j}, self.names{i});
                    elseif isempty(self.attributes(i).alias)
                        sql{j} = sprintf('%s,`%s`', sql{j}, self.names{i});
                    else
                        % aliased attributes
                        if strcmp(self.attributes(i).type,'float')  % cast to double to avoid rounding problems
                            
                            sql{j} = sprintf('%s,1.0*`%s` AS `%s`', sql{j}, self.attributes(i).alias, self.names{i});
                        elseif strcmp(self.attributes(i).type,self.computedTypeString)
                            
                            sql{j} = sprintf('%s,(%s) AS `%s`', sql{j}, self.attributes(i).alias, self.names{i});
                        else
                            
                            sql{j} = sprintf('%s,`%s` AS `%s`', sql{j}, self.attributes(i).alias, self.names{i});
                        end
                    end
                    
                end
            end
            if isUnion
                sql = cellfun(@(x) x(2:end), sql, 'uniformoutput', false);
            else
                sql = sql{1}(2:end); % strip leading comma
            end
        end
        
        function ret = union(self, other)
            %add new functionality
            ret = sl.HeaderAnimalEvent(self);
            ret.headers = {self, other, 'union'};
            
            ret.attributes = self.attributes;
            for i=1:numel(other.names)
                [~,locb] = ismember(other.names{i}, self.names);
                if locb
                    %         assert(strcmp(other.attributes(i).type, self.attributes(locb).type), 'matching columns in union tables must be of same type');
                else
                    ret.attributes(end+1) = other.attributes(i);
                    %                     ret.header.names{end+1} = other.names{i};
                    %
                    %                     ret.header.dependentFields{end+1} = other.names{i};
                    %                     if other.attributes(i).isBlob
                    %                         ret.header.blobNames{end+1} = other.names{i};
                    %                     else
                    %                         ret.header.notBlobs{end+1} = other.names{i};
                    %                     end
                end
            end
            %             ret.header = derive(
            if ~ismember('event_type',{ret.attributes.name})
                f = fieldnames(ret.attributes);
                attr = cell2struct(cell(size(f)), f);
                attr.name = 'event_type';
                attr.type = 'fake';
                attr.iskey = true;
                attr.isnullable = true;
                attr.isautoincrement = false;
                attr.isNumeric = false;
                attr.isString = true;
                attr.isBlob = false;
                attr.alias = '';
                ret.attributes(end+1) = attr;
            end
        end
        
        %cast functionality to dj.internal.Header
        function names = get.names(self)
            names = {self.attributes.name};
        end
        
        function names = get.primaryKey(self)
            names = self.names([self.attributes.iskey]);
        end
        
        function names = get.dependentFields(self)
            names = self.names(~[self.attributes.iskey]);
        end
        
        function names = get.blobNames(self)
            names = self.names([self.attributes.isBlob]);
        end
        
        function names = get.notBlobs(self)
            names = self.names(~[self.attributes.isBlob]);
        end
        
        function yes = hasAliases(self)
            yes = ~all(arrayfun(@(x) isempty(x.alias), self.attributes));
        end
        
        function n = count(self)
            n = length(self.attributes);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function stripAliases(self)
            for i=1:length(self.attributes)
                self.attributes(i).alias = '';
            end
        end
        
        function ret = project(self, params)
            
            include = [self.attributes.iskey];  % always include the primary key
            for iAttr=1:length(params)
                if strcmp('*',params{iAttr})
                    include = include | true;   % include all attributes
                else
                    % process a renamed attribute
                    toks = regexp(params{iAttr}, ...
                        '^([a-z]\w*)\s*->\s*(\w+)', 'tokens');
                    if ~isempty(toks)
                        ix = find(strcmp(toks{1}{1},self.names));
                        assert(length(ix)==1,'Attribute `%s` not found',toks{1}{1});
                        assert(~ismember(toks{1}{2},union({self.attributes.alias},self.names)),...
                            'Duplicate attribute alias `%s`',toks{1}{2})
                        self.attributes(ix).name = toks{1}{2};
                        self.attributes(ix).alias = toks{1}{1};
                    else
                        % process a computed attribute
                        toks = regexp(params{iAttr}, '(.*\S)\s*->\s*(\w+)', 'tokens');
                        if ~isempty(toks)
                            ix = self.count + 1;
                            self.attributes(ix) = struct(...
                                'name', toks{1}{2}, ...
                                'type',self.computedTypeString,...
                                'isnullable', false,...
                                'default', [], ...
                                'iskey', false, ...
                                'comment','server-side computation', ...
                                'isautoincrement', false, ...
                                'isNumeric', true, ...  % only numeric computations allowed for now, deal with character string expressions somehow
                                'isString', false, ...
                                'isBlob', false, ...
                                'alias', toks{1}{1});
                        else
                            % process a regular attribute
                            ix = find(strcmp(params{iAttr},self.names));
                            assert(~isempty(ix), 'Attribute `%s` does not exist', params{iAttr})
                        end
                    end
                    include(ix)=true;
                end
            end
            self.attributes = self.attributes(include);
            ret = sl.HeaderAnimalEvent(self);
            ret.headers = {self, [], 'project'};
            
        end
        
        function ret = join(hdr1, hdr2)
            % form the header of a relational join
            
            % merge primary keys
            ret = sl.HeaderAnimalEvent();
            ret.headers = {hdr1, hdr2, 'join'};
            
            ret.attributes = [hdr1.attributes([hdr1.attributes.iskey])
                hdr2.attributes([hdr2.attributes.iskey] & ~ismember(hdr2.names, hdr1.primaryKey))];
            
            % error if there are any matching dependent attributes
            commonDependent = intersect(hdr1.dependentFields,hdr2.dependentFields);
            if ~isempty(commonDependent)
                error('Matching dependent attribute `%s` must be projected out or renamed before relations can be joined.',...
                    commonDependent{1})
            end
            
            % merge dependent fields
            ret.attributes = [ret.attributes
                hdr1.attributes(~ismember(hdr1.names, ret.names))];
            ret.attributes = [ret.attributes
                hdr2.attributes(~ismember(hdr2.names, ret.names))];
            
        end
        
        function clause = makeWhereClause(header, restrictions)
            % make the where clause from self.restrictions
            persistent aliasCount
            if isempty(aliasCount)
                aliasCount = 0;
            else
                aliasCount = aliasCount + 1;
            end
            
            assert(all(arrayfun(@(x) isempty(x.alias), header.attributes)), ...
                'aliases must be resolved before restriction')
            
            clause = '';
            not = '';
            
            for arg = restrictions
                cond = arg{1};
                switch true
                    case isa(cond, 'sl.AnimalEvent') && strcmp(cond.operator, 'union')
                        % union
                        s = cellfun(@(x) makeWhereClause(header, {x}), cond.operands, 'uni', false);
                        assert(~isempty(s))
                        s = sprintf('(%s) OR ', s{:});
                        clause = sprintf('%s AND %s(%s)', clause, not, s(1:end-4));  % strip trailing " OR "
                        
                    case isa(cond, 'sl.AnimalEvent') && strcmp(cond.operator, 'not')
                        clause = sprintf('%s AND NOT(%s)', clause, ...
                            makeWhereClause(header, cond.operands));
                        
                    case dj.lib.isString(cond) && strcmpi(cond,'NOT')
                        % negation of the next condition
                        not = 'NOT ';
                        continue
                        
                    case dj.lib.isString(cond) && ~strcmpi(cond, 'NOT')
                        % SQL condition
                        clause = sprintf('%s AND %s(%s)', clause, not, cond);
                        
                    case isstruct(cond)
                        % restriction by a structure array
                        cond = dj.struct.proj(cond, header.names{:}); % project onto common attributes
                        if isempty(fieldnames(cond))
                            % restrictor has no common attributes:
                            %    semijoin leaves relation unchanged.
                            %    antijoin returns the empty relation.
                            if ~isempty(not)
                                clause = ' AND FALSE';
                            end
                        else
                            if ~isempty(cond)
                                % normal restricton
                                clause = sprintf('%s AND %s(%s)', clause, not, struct2cond(cond, header));
                            else
                                if isempty(cond)
                                    % restrictor has common attributes but is empty:
                                    %     semijoin makes the empty relation
                                    %     antijoin leavs relation unchanged
                                    if isempty(not)
                                        clause = ' AND FALSE';
                                    end
                                end
                            end
                        end
                        
                    case isa(cond, 'dj.internal.GeneralRelvar')
                        % semijoin or antijoin
                        [condHeader, condSQL] = cond.compile;
                        
                        % isolate previous projection (if not already)
                        if ismember(cond.operator, {'proj','aggregate'}) && isempty(cond.restrictions) && ...
                                ~all(cellfun(@isempty, {cond.header.attributes.alias}))
                            condSQL = sprintf('(SELECT %s FROM %s) as `$u%x`', ...
                                condHeader.sql, condSQL, aliasCount);
                        end
                        
                        % common attributes for matching. Blobs are not included
                        commonDependent = intersect(header.dependentFields,condHeader.dependentFields);
                        if ~isempty(commonDependent)
                            error('Cannot restrict by dependent attribute `%s`.  It must be projected out or renamed before restriction.',commonDependent{1})
                        end
                        commonAttrs = intersect(header.names, condHeader.names);
                        if isempty(commonAttrs)
                            % no common attributes. Semijoin = original relation, antijoin = empty relation
                            if ~isempty(not)
                                clause = ' AND FALSE';
                            end
                        else
                            % make semijoin or antijoin clause
                            commonAttrs = sprintf( ',`%s`', commonAttrs{:});
                            commonAttrs = commonAttrs(2:end);
                            clause = sprintf('%s AND ((%s) %s IN (SELECT %s FROM %s))',...
                                clause, commonAttrs, not, commonAttrs, condSQL);
                        end
                end
                not = '';
            end
            if length(clause)>6
                clause = clause(6:end); % strip " AND "
            end
        end
        
        function ret = byName(self, name)
            % get attribute structure by  name
            ix = strcmp(name,{self.attributes.name});
            assert(any(ix),'attribute %s not found', name)
            ret = self.attributes(ix);
        end
        
    end
end

function cond = struct2cond(keys, header)
% convert the structure array into an SQL condition
n = length(keys);
assert(n>=1)
if n>512
    warning('DataJoint:longCondition', ...
        'consider replacing the long array of keys with a more succinct condition')
end
cond = '';
for key = keys(:)'
    cond = sprintf('%s OR (%s)', cond, makeCond(key));
end
cond = cond(min(end,5):end);  % strip " OR "

    function subcond = makeCond(key)
        subcond = '';
        for field = fieldnames(key)'
            value = key.(field{1});
            attr = header.byName(field{1});
            assert(~attr.isBlob, 'The key must not include blob header.')
            if attr.isString
                assert(ischar(value), ...
                    'Value for key.%s must be a string', field{1})
                value = sprintf('''%s''', escapeString(value));
            else
                assert((isnumeric(value) || islogical(value)) && isscalar(value), ...
                    'Value for key.%s must be a numeric scalar', field{1});
                if isa(value, 'uint64')
                    value = sprintf('%u', value);
                elseif isa(value, 'int64')
                    value = sprintf('%i', value);
                else
                    value = sprintf('%1.16g', value);
                end
            end
            subcond = sprintf('%s AND `%s`=%s', subcond, field{1}, value);
        end
        subcond = subcond(min(6,end):end);  % strip " AND "
    end
end
