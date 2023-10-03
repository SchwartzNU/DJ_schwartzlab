function str = printEvents(ev)
printFields = ev.printFields;
printStr = ev.printStr;

if any(strcmp(printFields, 'cage_number'))
    ev = sln_animal.AnimalEvent * ev * sln_animal.Cage;
else
    ev = sln_animal.AnimalEvent * ev;
end

events = cell(size(printFields));
[events{:}] = ev.fetchn(printFields{:}); %fetch only the desired fields

recorded = strcmp(printFields,'recorded');
if any(recorded) %we want to parse these
    fname = strcmp(printFields,'fname');
    isRecorded = strcmp(events{recorded},'T');
    [events{recorded}{isRecorded}] = events{fname}{isRecorded};
    [events{recorded}{~isRecorded}] = deal('Not recorded');
    events(fname) = [];
end

numeric = cellfun(@(x) ~isa(x,'cell'), events);
events(numeric) = cellfun(@num2cell, events(numeric),'uniformoutput', false); %convert everything to a cell array
events = horzcat(events{:})';

str = strrep(sprintf(printStr, events{:}),' ()',''); %events are in same order as printFields
