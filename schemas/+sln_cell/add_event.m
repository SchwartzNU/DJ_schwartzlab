function [inserted, text] = add_event(key, event_type, C)
if nargin<3
    C = dj.conn;
    C.startTransaction;
end
inserted = false;
text = sprintf('');
try

    %MAIN INSERT of this event type    
    %key
    key = insert(sln_cell.CellEvent, key);
    insert(feval(sprintf('sln_cell.%s',event_type)), key);

    text = sprintf('%s insert successful.\n%s', event_type, text);
    if nargin<3
        C.commitTransaction;   
        fprintf(text);
        inserted = true;
    end 
catch ME    
    fprintf('%s insert failed.\n', event_type);
    if nargin<3
        C.cancelTransaction;
    end
    inserted = false;
    text = ME.message;
    disp(text);
end
