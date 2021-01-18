dj.conn;
while true
    disp(datestr(now));
    try
        populateAll();
    catch ME
        messagetext = getReport(ME);
        disp(messagetext);
    end
    pause(10);
end