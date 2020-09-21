function [] = add_animalEvent(key, event_type)
C = dj.conn;
C.startTransaction
try 
    key_AnimalEvent.date = key.date;   
    key_AnimalEvent.animal_id = key.animal_id;
    eventsThisDate = sl.AnimalEvent & ['animal_id=' num2str(key.animal_id)] & ['date=' '"' key.date '"'];
    
    if eventsThisDate.exists
        key_AnimalEvent.event_id = max(fetchn(eventsThisDate, 'event_id')) + 1;
    else
        key_AnimalEvent.event_id = 1;
    end
    insert(sl.AnimalEvent, key_AnimalEvent);    
    
    key.event_id = key_AnimalEvent.event_id;
    insert(eval(['sl.AnimalEvent' event_type]), key);    
    disp('Insert successful');
    C.commitTransaction;    
catch
    errordlg('Insert failed');
    C.cancelTransaction;
end