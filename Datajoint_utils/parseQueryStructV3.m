function q = parseQueryStructV3(queryState, searchTable, toString)
if nargin<3
    toString = false;
end

q = '';
C = dj.conn;
if ~C.isConnected
    disp('DataJoint connection failed.');
    return
end

if length(queryState.operatorColumn) < 1 %empty so return
    q = eval('searchTable');
    return;
end

if startsWith(strtrim(queryState.logicButtonColumn(1).text),'ANY OF')
    %special case where logical comes first
    logicals_first = true;
else
    logicals_first = false;
end

Nrows = length(queryState.attributeColumn);
for i=1:Nrows
    curOp = queryState.operatorColumn(i).value;
    curType = queryState.attributeColumn(i).type;

    curName = queryState.attributeColumn(i).name;
    if strcmp(curType, 'date')
        curValue = datestr(queryState.queryEntryColumn(i).value, 'yyyy-mm-dd');
    else
        curValue = queryState.queryEntryColumn(i).value;
    end

    val = curValue;
    switch curOp
        case 'is'
            op = '=';
        case 'is not'
            op = '!=';
        case 'is like'
            op = 'LIKE';
        case 'is NULL'
            op = ' IS ';
            val = NaN;
        otherwise
            op = curOp;
    end

    if isnan(val)
        entry{i} = [curName, op, 'NULL'];
    elseif strcmp(op,'LIKE')
        entry{i} = [curName, ' LIKE ', '"', val, '"'];
    elseif ischar(val)
        entry{i} = [curName, op, '"', val, '"'];
    else
        entry{i} = [curName, op, num2str(val)];
    end
end

%now just parse the logic and run it!

%first assemble
Qstr = ['searchTable & '];
Qstr_human = ['searchTable & '];
for i=1:length(entry)
    if logicals_first && i==1
        txt = queryState.logicButtonColumn(i).text;
        if ~isempty(txt)
            txt = strtrim(txt);
            switch txt
                case 'AND'
                    Qstr = [Qstr, '& '];
                    Qstr_human = [Qstr_human, '& '];
                case 'AND NOT'
                    %special case for this because it needs to be a separate clause
                    Qstr = ['( ', Qstr ' )', ' - '];
                    Qstr_human = ['( ', Qstr_human ' )', ' - '];
                case ') AND NOT'
                    %special case for this because it needs to be a separate clause
                    Qstr = ['( ', Qstr '] )', ' - '];
                    Qstr_human = ['( ', Qstr_human '] )', ' - '];
                case ') AND NOT ANY OF ('
                    %special case for this because it needs to be a separate clause
                    Qstr = ['( ', Qstr '] )', ' - ['];
                    Qstr_human = ['( ', Qstr_human '] )', ' - '];
                case 'AND NOT ANY OF ('
                    %special case for this because it needs to be a separate clause
                    Qstr = ['( ', Qstr ' )', ' - ['];
                    Qstr_human = ['( ', Qstr_human ' )', ' - ['];
                case 'AND ANY OF (' %% this is currently broken in DataJoint!!! https://github.com/datajoint/datajoint-matlab/issues/96, trying using 'OR'
                    Qstr = [Qstr, '& [ '];
                    Qstr_human = [Qstr_human, '& [ '];
                case 'ANY OF ('
                    Qstr = [Qstr, '[ '];
                    Qstr_human = [Qstr_human, '[ '];
                case ')'
                    Qstr = [Qstr, '] '];
                    Qstr_human = [Qstr_human, '] '];
                case ') AND'
                    Qstr = [Qstr, '] & '];
                    Qstr_human = [Qstr_human, '] & '];
                case ') AND ANY OF ('
                    Qstr = [Qstr, '] & [ '];
                    Qstr_human = [Qstr_human, '] & [ '];
                case ','
                    Qstr = [Qstr, ' '' OR '' '];
                    Qstr_human = [Qstr_human, ' '' OR '' '];
            end
        end
    end
    if logicals_first 
        txt = queryState.logicButtonColumn(i+1).text;
    else
        txt = queryState.logicButtonColumn(i).text;
    end
    if ~isempty(entry{i})
        Qstr = [Qstr, 'entry{' num2str(i) '} '];
        thisEntry = entry{i};
        Qstr_human = [Qstr_human, '''' thisEntry ''''];
    end
    if ~isempty(txt)
        txt = strtrim(txt);
        switch txt
            case 'AND'
                Qstr = [Qstr, '& '];
                Qstr_human = [Qstr_human, '& '];
            case 'AND NOT'
                %special case for this because it needs to be a separate clause
                Qstr = ['( ', Qstr ' )', ' - '];
                Qstr_human = ['( ', Qstr_human ' )', ' - '];
            case ') AND NOT'
                %special case for this because it needs to be a separate clause
                Qstr = ['( ', Qstr '] )', ' - '];
                Qstr_human = ['( ', Qstr_human '] )', ' - '];
            case ') AND NOT ANY OF ('
                %special case for this because it needs to be a separate clause
                Qstr = ['( ', Qstr '] )', ' - ['];
                Qstr_human = ['( ', Qstr_human '] )', ' - '];
            case 'AND NOT ANY OF ('
                %special case for this because it needs to be a separate clause
                Qstr = ['( ', Qstr ' )', ' - ['];
                Qstr_human = ['( ', Qstr_human ' )', ' - ['];
            case 'AND ANY OF (' %% this is currently broken in DataJoint!!! https://github.com/datajoint/datajoint-matlab/issues/96, trying using 'OR'
                Qstr = [Qstr, '& [ '];
                Qstr_human = [Qstr_human, '& [ '];
            case 'ANY OF ('
                Qstr = [Qstr, '[ '];
                Qstr_human = [Qstr_human, '[ '];
            case ')'
                Qstr = [Qstr, '] '];
                Qstr_human = [Qstr_human, '] '];
            case ') AND'
                Qstr = [Qstr, '] & '];
                Qstr_human = [Qstr_human, '] & '];
            case ') AND ANY OF ('
                Qstr = [Qstr, '] & [ '];
                Qstr_human = [Qstr_human, '] & [ '];
            case ','
                Qstr = [Qstr, ' '' OR '' '];
                Qstr_human = [Qstr_human, ' '' OR '' '];
        end
    end
end

%NOT restriciton currently broken (returns empty): DJ issue?
%Qstr_human

if toString %just return the string
    q = Qstr_human;
else %evaluate the string
    try
        q = eval(Qstr);
        C.close();
    catch ME
        C.close();
        disp('Parse error for string: ');
        disp(Qstr);
        %rethrow(ME);
    end
end



