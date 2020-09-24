function [] = add_animal(key)
C = dj.conn;
C.startTransaction
try    
    %test for duplicate tag_id
    if isfield(key,'tag_id')
       matchingIDEntry = sl.Animal & ['tag_id=' num2str(key.tag_id)];
       if matchingIDEntry.exists
           errordlg(['Animal with tag_id: ' num2str(key.tag_id) ' already in database']);
           error('Duplicate entry');
       end
    end
    insert(sl.Animal, key);    
    disp('Insert successful');
    C.commitTransaction;    
catch
    errordlg('Insert failed');
    C.cancelTransaction;
end