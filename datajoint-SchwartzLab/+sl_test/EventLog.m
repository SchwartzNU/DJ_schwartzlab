%
% Note -- this is NOT a dj table, but rather a way to interface with tables
%         while using grouped LIMIT operations
%
classdef EventLog < dj.internal.GeneralRelvar

    methods

        function [ret, keys] = fetch(self, varargin)
            %note that any operations to the table should return a generalrelvar object, so we should be safe
            %in other words this will only work on the 'pure' table

            if any(cellfun(@(x) contains(x, 'PER'), varargin))
                [limit, per, args] = makeLimitClause(varargin{:});
                selectors = parseArgs(args);
                ret = self.schema.conn.query(sprintf(...
                    'SELECT * FROM ( SELECT %sRANK() OVER (PARTITION BY %s ORDER BY datetime %s) AS rnk FROM `%s`.`%s`) AS x WHERE rnk <= %s%s', ...
                    selectors,per.selector, per.order, self.schema.dbname, self.plainTableName, per.limit, limit ...
                ));
                ret = dj.struct.fromFields(rmfield(ret,'rnk'));
            else
                [ret, keys] = fetch@dj.internal.GeneralRelvar(self, varargin{:});
            end

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
        selectors = '*';
    else
        selectors = sprintf('%s,',args{:});
    end
end