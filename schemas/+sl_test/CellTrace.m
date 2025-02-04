%{
# Cell tracing

trace_id : int unsigned auto_increment #unique trace id
---
-> sl_test.CellImage      #what image does the tracing correspond to?
-> sl_test.User           #who did the tracing?

fname : varchar(128)      #tracing filename

%}

classdef CellTrace < dj.Imported
end