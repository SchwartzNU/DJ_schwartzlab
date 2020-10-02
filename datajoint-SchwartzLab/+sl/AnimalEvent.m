%
% Note -- this is NOT a dj table, but rather a way to interface with tables
%         that record events
%
classdef AnimalEvent < dj.internal.GeneralRelvar
    
    properties
        query
        operator ='table'
        operands={}
    end
    
    methods(Static)
        function query = all()
            query = [];
            tables = sl.getSchema().tableNames.keys();
            for table = tables
                t = feval(table{:});
                m = metaclass(t);
                if any(strcmp({m.SuperclassList(:).Name},'sl.AnimalEvent'))
                    %this table is an event table
                    if isempty(query)
                        query = t;
                    else
                        query = query | t;
                    end
                end
            end
        end
    end
    
    methods
        
        function [ret, keys] = fetch(self, varargin)
            %note that any operations to the table should return a generalrelvar object, so we should be safe
            %in other words this will only work on the 'pure' table
            
            %             if any(cellfun(@(x) contains(x, 'PER'), varargin))
            %                 [limit, per, args] = makeLimitClause(varargin{:});
            %                 if isempty(args)
            %                     args = self.primaryKey;
            %                 end
            %                 selectors = parseArgs(args);
            %                 ret = self.schema.conn.query(sprintf(...
            %                     'SELECT * FROM ( SELECT %sRANK() OVER (PARTITION BY %s ORDER BY %s %s) AS rnk FROM %s) AS x WHERE rnk <= %s%s', ...
            %                     selectors, per.selector, per.orderby, per.order, self.get('query'), per.limit, limit ...
            %                     ));
            %                 ret = dj.struct.fromFields(rmfield(ret,'rnk'));
            %             else
            %                 self = self.proj(args{:});
            %                 [hdr, sql_] = self.compile;
            %             end
            
            [limit, per, args, outer] = makeLimitClause(varargin{:});
            
            if ~isempty(args)
                self = self.proj(args{:});
            end
            [hdr, sql_] = self.compile;
            
            if ~isempty(outer)
            sql = enclose(hdr, sql_, inf, per); %need to pass limit, per, args...
            hdr.attributes = hdr.attributes(ismember(hdr.names, outer));
            sql = enclose(hdr, sql, limit);
            else
               sql = enclose(hdr, sql_, limit, per); 
            end
            
            ret = sl.getSchema().conn.query(sql);
            % if ~isempty(per)
            %    ret =rmfield(ret,'rnk'); 
            % end
            ret = dj.struct.fromFields(ret);
            
            if nargout>1
                % return primary key structure array
                keys = dj.struct.proj(ret,self.primaryKey{:});
            end
            
        end
        
        function varargout = fetchn(self, varargin)
            
            [limit, per, args] = makeLimitClause(varargin{:});
            specs = args(cellfun(@(x) ischar(x) && ismember(x, varargin), args)); % attribute specifiers
%             returnKey = nargout==length(specs)+1;
            returnKey = false;
            assert(returnKey || (nargout==length(specs) || (nargout==0 && length(specs)==1)), ...
                'The number of fetchn() outputs must match the number of requested attributes')
            assert(~isempty(specs),'insufficient inputs')
            assert(~any(strcmp(specs,'*')), '"*" is not allowed in fetchn()')
            
            % submit query
            if ~isempty(args)
                self = self.proj(args{:});  % this copies the object, so now it's a different self
            end
            
            [hdr, sql_] = self.compile;
            sql = enclose(hdr, sql_, limit, per);
            
            ret = sl.getSchema().conn.query(sql);
            if ~isempty(per)
               ret =rmfield(ret,'rnk'); 
            end
            
            % copy into output arguments
            varargout = cell(length(specs));
            for iArg=1:length(specs)
                % if renamed, use the renamed attribute
                name = regexp(specs{iArg}, '(\w+)\s*$', 'tokens');
                varargout{iArg} = ret.(name{1}{1});
            end
            
%             if returnKey
%                 varargout{length(specs)+1} = dj.struct.fromFields(dj.struct.proj(ret, self.primaryKey{:}));
%             end
        end
        
        function varargout = fetch1(self, varargin)
            varargout = cell(nargout,1);
            [varargout{:}] = self.fetchn(varargin{:});
            
            assert(length(varargout{1}) == 1,'fetch1 can only retrieve a single existing tuple.');
            % if any(cellfun(@(x) contains(x, 'PER'), varargin))
            %     varargout = sl.EventLog.fetchn(self, varargin);
            
            % else
            %     varargout = cell(nargout,1);
            %     [varargout{:}] = fetch1@dj.internal.GeneralRelvar(self, varargin{:});
            % end
        end
        
        function ret = mtimes(self, arg)
            ret = join(self, arg);
        end
        
        function ret = join(self, arg)
            assert(isa(arg, 'dj.internal.GeneralRelvar'), ...
                'mtimes requires another relvar as operand')
            ret = init(sl.AnimalEvent, 'join', {self arg});
            ret.operator = 'join';
            ret.operands = {self arg};
        end
        
        function ret = proj(self, varargin)
            if nargin>2 && isa(varargin{1}, 'dj.internal.GeneralRelvar')
                % if the first argument is a relvar, perform aggregation
                ret = self.aggr(varargin{1}, varargin{2:end});
            else
                assert(iscellstr(varargin), 'proj() requires a list of strings as attribute args')
                ret = init(sl.AnimalEvent, 'proj', [{self} varargin]);
                ret.operator = 'proj';
                ret.operands = [{self} varargin];
            end
        end
        
        function ret = aggr(self, other, varargin)
            assert(iscellstr(varargin), 'proj() requires a list of strings as attribute args')
            ret = init(sl.AnimalEvent, 'aggregate', [{self, other} varargin]);
            ret.operator = 'aggregate';
            ret.operands = [{self, other} varargin];
        end
        
        function ret = or(self, arg)
            assert(isa(arg, 'sl.AnimalEvent'),'cannot unify inputs. Did you mean to switch the operand order?');
            %this is because we don't have access to the GeneralRelvar
            %props
            
%             if ~strcmp(self.operator, 'union')
%                 operandList = {self};
%             else
%                 operandList = self.operands;
%             end
%             
%             % expand recursive unions
%             if ~strcmp(arg.operator, 'union')
%                 operandList = [operandList {arg}];
%             else
%                 operandList = [operandList arg.operands];
%             end
            ret = init(sl.AnimalEvent, 'union', [{self} {arg}]);
            ret.operator = 'union';
            ret.operands = [{self} {arg}];
        end
        
        function ret = and(self, arg)
            % AND - relational restriction
            %
            % R1 & cond  yeilds a relation containing all the tuples in R1
            % that match the condition cond. The condition cond could be an
            % structure array, another relation, or an sql boolean
            % expression.
            %
            % Examples:
            %   tp.Scans & struct('mouse_id',3, 'scannum', 4);
            %   tp.Scans & 'lens=10'
            %   tp.Mice & (tp.Scans & 'lens=10')
            ret = self.copy;
            if isa(arg,'dj.internal.GeneralRelvar') && ~isa(arg,'sl.AnimalEvent')
%                 th = arg.tableHeader;
                newarg = init(sl.AnimalEvent, 'wrapper', {arg});
                newarg.operator = 'wrapper';
                newarg.operands = {arg};
%                 arg.tableHeader = th;
            else
                newarg = arg;
            end
            ret.restrict(newarg);
        end
        
        function disp(self)
            fprintf('displaying via AnimalEvent');
            %union is not yet implemented for general tables but we can
            %override for this case...
            tic
            fprintf('\nObject %s\n\n',class(self))
            hdr = self.compile(); %need to override
            
            attrList = cell(size(hdr.attributes));
            for i = 1:length(hdr.attributes)
                if hdr.attributes(i).isBlob
                    attrList{i} = sprintf('("=BLOB=") -> %s', hdr.names{i});
                else
                    attrList{i} = hdr.names{i};
                end
            end
            maxRows = dj.set('maxPreviewRows');
            preview = self.fetch(attrList{:}, sprintf('LIMIT %d', maxRows+1));
            if ~isempty(preview)
                hasMore = length(preview) > maxRows;
                preview = struct2table(preview(1:min(end,maxRows)), 'asArray', true);
                % convert primary key to upper case:
                funs = {@(x) x; @upper};
                preview.Properties.VariableNames = cellfun(@(x) funs{1+ismember(x, self.compile().primaryKey)}(x), ...
                    preview.Properties.VariableNames, 'uni', false);
                disp(preview)
                if hasMore
                    fprintf '          ...\n\n'
                end
            end
            fprintf('%d tuples (%.3g s)\n\n', self.count, toc)
        end
        
        function n = count(self, varargin)
            % COUNT - the number of tuples in the relation.
            [limit, per, args] = makeLimitClause(varargin{:});
            
            self = self.proj(args{:});
                
            [hdr, sql_] = self.compile;
            
            sql = enclose(hdr, sql_, limit, per, 'count'); %need to pass limit, per, args...
            
%             [hdr, sql_] = self.compile(3);
%             sql = hdr.enclose(sql_, '', 'count');
            n = sl.getSchema().conn.query(sql);
            n = double(n.n);
        end
        
        function [header, sql] = compile(self, enclose)
            
            persistent aliasCount
            if isempty(aliasCount)
                aliasCount = 1;
            end
            if nargin<2
                enclose = 0;
            end
            
            % apply relational operators recursively
            switch self.operator
                case 'union'
                    [header1, sql1] = compile(self.operands{1},2);
                    [header2, sql2] = compile(self.operands{2},2);
                    %                     sql = sprintf('%s UNION %s', sql1, sql2);
                    sql = {sql1, sql2};
                    header = union(header1,header2);
                    clear header1 header2 sql1 sql2
                    
                case 'not'
                    throwAsCaller(MException('DataJoint:invalidOperator', ...
                        'The NOT operator must be used in a restriction'))
                    
                case 'table'  % terminal node
                    %note that the tables derive from dj.Table, but the
                    %relations do not
                    tab = self;
                    header = sl.HeaderAnimalEvent(derive(tab.tableHeader), tab.className);
                    sql = tab.fullTableName;
                case 'wrapper'
%                     [header, sql] = compile(self.operands{1},1);
                    header = sl.HeaderAnimalEvent(derive(self.operands{1}.tableHeader));
                    sql = self.operands{1}.fullTableName;
                    
                case 'proj'
                    [header, sql] = compile(self.operands{1},1);
                    if isa(sql,'cell')
                        sql = header.enclose(sql, aliasCount);
                        aliasCount = aliasCount+1;
                    end
                    header = header.project(self.operands(2:end));
                    
                case 'aggregate'
                    if ~isa(self.operands{1}, 'sl.AnimalEvent')
                        header = sl.HeaderAnimalEvent(self.operands{1}.header);
                        sql = self.operands{1}.sql;
                    else
                        [header, sql] = compile(self.operands{1},2);
                    end
                    if ~isa(self.operands{2}, 'sl.AnimalEvent')
                        header2 = sl.HeaderAnimalEvent(self.operands{2}.header);
                        sql2 = self.operands{2}.sql;
                    else
                        [header2, sql2] = compile(self.operands{2},2);
                    end
                    commonBlobs = intersect(header.blobNames, header2.blobNames);
                    assert(isempty(commonBlobs), 'join cannot be done on blob attributes')
                    pkey = sprintf(',`%s`', header.primaryKey{:});
                    sql = sprintf('%s NATURAL LEFT JOIN %s GROUP BY %s', sql, sql2, pkey(2:end));
                    header.project(self.operands(3:end));
                    assert(~all(arrayfun(@(x) isempty(x.alias), header.attributes)),...
                        'Aggregate operators must define at least one computation')
                    
                case 'join'
                    if ~isa(self.operands{1},'sl.AnimalEvent')
                        %it's a relvar so we don't have access to compile
                        header1 = sl.HeaderAnimalEvent(self.operands{1}.header);
                        %                         sql1 = header1.enclose(self.operands{1}.sql, '');
                        sql1 = self.operands{1}.sql;
                    else
                        [header1, sql1] = compile(self.operands{1},2);
                    end
                    if ~isa(self.operands{2},'sl.AnimalEvent')
                        %it's a relvar so we don't have access to compile
                        header2 = sl.HeaderAnimalEvent(self.operands{2}.header);
                        %                         sql2 = header2.enclose(self.operands{2}.sql, '');
                        sql2 = self.operands{2}.sql;
                    else
                        [header2, sql2] = compile(self.operands{2},2);
                    end
                    
                    sql = sprintf('%s NATURAL JOIN %s', sql1, sql2);
                    header = join(header1,header2);
                    clear header1 header2 sql1 sql2
                    
                otherwise
                    error 'unknown relational operator'
            end
            
            % apply restrictions
            if ~isempty(self.restrictions)
                % clear aliases and enclose
                if header.hasAliases
                    %                     sql = sprintf('(SELECT %s FROM %s) as `$s%x`', header.sql, sql, aliasCount);
                    sql = header.enclose(sql, aliasCount);
                    aliasCount = aliasCount + 1;
                    header.stripAliases;
                end
                
                isPer = cellfun(@(x) isa(x,'char') && contains(x,'PER'), self.restrictions);
                if any(isPer)
                    assert(nnz(isPer)==1, 'only one PER state is allowed for a single relation.');
                    [~,per,~] = makeLimitClause(self.restrictions{isPer});
                    perInd = find(isPer);
                else
                    perInd = length(self.restrictions)+1;
                end
                
                
                % add WHERE clause
                %NEED to parse case that sql is a cell ~~~~
                whereClause = makeWhereClause(header, self.restrictions(1:perInd-1));
                if ~isempty(whereClause)
                    if isa(sql, 'cell')
                        sql = horzcat(sql{:}, 'WHERE %s', whereClause);
                    else
                        sql = sprintf('%s WHERE %s', sql, whereClause);
                    end
                end
                
                if any(isPer)
                    sql = header.enclose(sql, aliasCount, per);
%                     header 
                    aliasCount = aliasCount + 3;
                    % add WHERE clause
%                     sql = sprintf('%s%s', sql); %?????
                    whereClause = makeWhereClause(header, self.restrictions(perInd+1:end));
                    if ~isempty(whereClause)
                        if isa(sql, 'cell') %can't actually be a cell here because of the enclose...
                            sql = horzcat(sql{:}, 'WHERE %s', whereClause);
                        else
                            sql = sprintf('%s WHERE %s', sql, whereClause);
                        end
                    end
                end
                
            end
            
            % enclose in subquery if necessary
            if enclose==1 && header.hasAliases ...
                    || enclose==2 && (~ismember(self.operator, {'table', 'join'}) || ~isempty(self.restrictions)) ...
                    || enclose==3 && strcmp(self.operator, 'aggregate')
                %                 sql = sprintf('(SELECT %s FROM %s) AS `$a%x`', header.sql, sql, aliasCount);
                sql = header.enclose(sql, aliasCount);
                aliasCount = aliasCount + 1;
                header.stripAliases;
            end
        end
        
%         function header = get.header(self)
%             header = self.compile;
%         end
        
    end
end

function [limit, per, args, outer] = makeLimitClause(varargin)
args = varargin;
limit = '';
per = [];
outer = {};

if isempty(args)
   return 
end

lastArg = args{end};

%check if there is a limit operation at the end
if strcmp(lastArg,'*')
    return
end

if ischar(lastArg) && ~contains(lastArg, 'PER') && (strncmp(strtrim(varargin{end}), 'ORDER BY', 8) || strncmp(varargin{end}, 'LIMIT ', 6))
    limit = [' ' lastArg];
    args = args(1:end - 1);
    lastArg = args{end};
elseif isnumeric(lastArg)
    limit = sprintf(' LIMIT %d', lastArg);
    args = args(1:end - 1);
    lastArg = args{end};
end

if ischar(lastArg) && contains(lastArg,'PER')
    per = regexp(lastArg,'^LIMIT\s(?<limit>\d+)\sPER\s(?<selector>\w+)\s*(ORDER\sBY)?(?<orderby>(([\s*\w*\s*,?])*))','names');
    %     if isempty(per.selector)
    %         per.selector = 'animal_id';
    %     end
    if isempty(per.orderby) || strcmp(per.orderby,'DESC')
        per.orderby = '`date` DESC, `time` DESC, `entry_time` DESC'; %default sorting
        tokens = {'date', 'time', 'entry_time'};
    elseif strcmp(per.orderby, 'ASC')
        per.orderby = '`date` ASC, `time` ASC, `entry_time` ASC';
        tokens = {'date', 'time', 'entry_time'};
    else 
        tokens = regexp(per.orderby, '([a-z0-9_]+)','tokens');
        order = regexp(per.orderby, '((DESC)?(ASC)?)','tokens');
        per.orderby = join(cellfun(@(x,y) sprintf('`%s` %s',x,y),horzcat(tokens{:}), horzcat(order{:}), 'uniformOutput', false),',');
        per.orderby = per.orderby{:};
    end
    args = args(1:end-1);
    if ~isempty(args)
       %we need to make sure that orderby and selector are both in
       %projection
       outer = args;
       if ~ismember(per.selector, args)%all(cellfun(@isempty, regexp(args, sprintf('^(?<selector>%s)',per.selector))))
           args{end+1} = per.selector;
       end
       
       args = union(args, tokens);
%        
%        if all(cellfun(@isempty, regexp(args, sprintf('^(?<orderby>%s)',per.orderby))))
%            args = horzcat(args, tokens);
%        end
       
    end
end

end

function selectors = parseArgs(args)
selectors = sprintf('%s,',args{:});
end
