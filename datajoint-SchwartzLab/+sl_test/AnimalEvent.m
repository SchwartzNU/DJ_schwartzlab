%
% Note -- this is NOT a dj table, but rather a way to interface with tables
%         that record events
%
classdef AnimalEvent < dj.internal.GeneralRelvar
    
    methods(Static)
        function res = get(varargin)
            %fetch all corresponding events from all event tables
            res = [];
            tables = sl_test.getSchema().tableNames.keys();
            for table = tables
                t = feval(table{:});
                m = metaclass(t);
                if any(strcmp({m.SuperclassList(:).Name},'sl_test.AnimalEvent'))
                    %this table is an event table
                    q = t.fetch(varargin{:});
                    [q.event_type] = deal(erase(table{:},'sl_test.AnimalEvent'));
                    if isempty(res)
                        res = q;
                    else
                        for field = setdiff(fieldnames(q), fieldnames(res))'
                            if ~isempty(field)
                                [res.(field{:})] = deal('NULL');
                            end
                        end
                        for field = setdiff(fieldnames(res), fieldnames(q))'
                            if ~isempty(field)
                                [q.(field{:})] = deal('NULL');
                            end
                        end
                        res = vertcat(res,q);
                    end
                end
            end
        end
    end
    
    methods
        
        function [ret, keys] = fetch(self, varargin)
            %note that any operations to the table should return a generalrelvar object, so we should be safe
            %in other words this will only work on the 'pure' table
            
            if any(cellfun(@(x) contains(x, 'PER'), varargin))
                [limit, per, args] = makeLimitClause(varargin{:});
                selectors = parseArgs(args);
                ret = self.schema.conn.query(sprintf(...
                    'SELECT * FROM ( SELECT %sRANK() OVER (PARTITION BY %s ORDER BY datetime %s) AS rnk FROM %s) AS x WHERE rnk <= %s%s', ...
                    selectors,per.selector, per.order, self.sql, per.limit, limit ...
                    ));
                ret = dj.struct.fromFields(rmfield(ret,'rnk'));
            else
                [ret, keys] = fetch@dj.internal.GeneralRelvar(self, varargin{:});
            end
            
        end
        
        function varargout = fetchn(self, varargin)
            if any(cellfun(@(x) contains(x, 'PER'), varargin))
                [limit, per, args] = makeLimitClause(varargin{:});
                
                
                returnKey = nargout==length(args)+1;
                
                assert(returnKey || (nargout==length(args) || (nargout==0 && length(args)==1)), ...
                    'The number of fetchn() outputs must match the number of requested attributes')
                assert(~isempty(args),'insufficient inputs');
                assert(~any(strcmp(args,'*')), '"*" is not allowed in fetchn()');
                
                selectors = parseArgs(args);
                
                ret = self.schema.conn.query(sprintf(...
                    'SELECT * FROM ( SELECT %sRANK() OVER (PARTITION BY %s ORDER BY datetime %s) AS rnk FROM %s) AS x WHERE rnk <= %s%s', ...
                    selectors,per.selector, per.order, self.sql, per.limit, limit ...
                    ));
                
                varargout = struct2cell(rmfield(ret,'rnk'));
                
                if returnKey
                    varargout{end+1} = dj.struct.fromFields(dj.struct.proj(ret, self.primaryKey{:}));
                end
                
            else
                varargout = cell(nargout,1);
                [varargout{:}] = fetchn@dj.internal.GeneralRelvar(self, varargin{:});
            end
        end
        
        function varargout = fetch1(self, varargin)
            varargout = cell(nargout,1);
            [varargout{:}] = self.fetchn(varargin{:});
            
            assert(length(varargout{1}) == 1,'fetch1 can only retrieve a single existing tuple.');
            % if any(cellfun(@(x) contains(x, 'PER'), varargin))
            %     varargout = sl_test.EventLog.fetchn(self, varargin);
            
            % else
            %     varargout = cell(nargout,1);
            %     [varargout{:}] = fetch1@dj.internal.GeneralRelvar(self, varargin{:});
            % end
        end
    end
    
end

function [limit, per, args] = makeLimitClause(varargin)
%we know the clause contains 'per'
args = varargin;
limit = '';

lastArg = args{end};

%check if there is a limit operation at the end
if ischar(lastArg) && ~contains(lastArg,'PER')
    limit = [' ' lastArg];
    args = args(1:end - 1);
    lastArg = args{end};
elseif isnumeric(lastArg)
    limit = sprintf(' LIMIT %d', lastArg);
    args = args(1:end - 1);
    lastArg = args{end};
end

if ischar(lastArg) && contains(lastArg,'PER')
    per = regexp(lastArg,'^LIMIT\s(?<limit>\d+)\sPER\s(?<selector>\w+)\s*(?<order>(DESC)?(ASC)?)','names');
    if isempty(per.order)
        per.order = 'DESC';
    end
    args = args(1:end-1);
end

end

function selectors = parseArgs(args)
if isempty(args)
    selectors = '*,';
else
    selectors = sprintf('%s,',args{:});
end
end