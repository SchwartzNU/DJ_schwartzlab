function q = parseQueryStruct(queryState)
q = '';
C = dj.conn;
if ~C.isConnected
    disp('DataJoint connection failed.');
    return
end

%make searchTable
currentTables = queryState.currentTables;
commandStr = 'searchTable=';
N = length(currentTables);
for i=1:N
    commandStr = [commandStr, 'sl.' currentTables{i} '*'];
end
%remove trailing *
commandStr = [commandStr(1:end-1) ,';'];
eval(commandStr);

if length(queryState.operatorColumn) < 1 %empty so return
    return
end


if isempty(queryState.operatorColumn(1).value)
    %special case where logical comes first
    rowInd = 3:2:length(queryState.attributeColumn);
else
    rowInd = 1:2:length(queryState.attributeColumn);
end

for i=rowInd
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
            op = '=';
            val = NaN;
        otherwise
            op = curOp;
    end
    
    if isnan(val)
        entry{i} = [curName, op, '"', 'NULL', '"'];
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
Qstr = ['searchTable & ']; %TODO - leading NOT changes this
for i=1:length(entry)
    if ~isempty(entry{i})
        Qstr = [Qstr, 'entry{' num2str(i) '} '];
    end
    txt = queryState.logicButtonColumn(i+1).text;
    if ~isempty(txt)
        txt = strtrim(txt);
        switch txt
            case 'AND'
                Qstr = [Qstr, '& '];
            case 'AND NOT'
                %special case for this because it needs to be a separate clause
                Qstr = ['( ', Qstr ' )', ' - '];
            case ') AND NOT'
                %special case for this because it needs to be a separate clause
                Qstr = ['( ', Qstr '} )', ' - '];
            case ') AND NOT ANY OF ('
                %special case for this because it needs to be a separate clause
                Qstr = ['( ', Qstr '} )', ' - {'];
            case 'AND NOT ANY OF ('
                %special case for this because it needs to be a separate clause
                Qstr = ['( ', Qstr ' )', ' - {'];    
            case 'AND ANY OF (' %% this is currently broken in DataJoint!!! https://github.com/datajoint/datajoint-matlab/issues/96
                Qstr = [Qstr, '& { '];
            case 'ANY OF ('
                Qstr = [Qstr, '{ '];
            case ')'
                Qstr = [Qstr, '} '];
            case ') AND'
                Qstr = [Qstr, '} & '];
            case ') AND ANY OF ('
                Qstr = [Qstr, '} & { '];
            case ','
                Qstr = [Qstr, ', '];
        end
    end
end

try
    q = eval(Qstr);
    C.close();
catch ME
    C.close();
    disp('Parse error for string: ');
    disp(Qstr);
    rethrow(ME);
end



