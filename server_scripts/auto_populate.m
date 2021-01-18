dj.conn;
while true
    disp(datestr(now));
    try
        populateAll();
    catch
        
    end
    pause(10);
end