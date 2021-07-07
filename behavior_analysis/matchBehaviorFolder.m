function session_id = matchBehaviorFolder(folder_name)
[id_str, fname] = fileparts(folder_name);

parts = strsplit(fname, '_');
date_str = parts{1};

thisSession = sl.AnimalEventSocialBehaviorSession & sprintf('animal_id=%s',id_str) & sprintf('date="%s"', date_str);
L = thisSession.count;

if L==0
    disp(['no matching session found for ' folder_name]);
    session_id = nan;
elseif L>1
    disp(['multiple matching sessions found for ' folder_name]);
    %use the rest of the name to figure it out
    session_id = nan;
else
    session_id = thisSession.fetchn('event_id'); %why is fetch1 not working?
end