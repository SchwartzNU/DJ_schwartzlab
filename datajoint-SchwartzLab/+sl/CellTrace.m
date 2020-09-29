%{
# Cell tracing

trace_id : int unsigned auto_increment #unique trace id
---
-> sl.CellImage      #what image does the tracing correspond to?
-> sl.User           #who did the tracing?

fname : varchar(128)      #tracing filename

%}

classdef CellTrace < dj.Imported
<<<<<<< HEAD
end
=======
end
>>>>>>> b5b06100d6d37fa75342a06db06f4c00b394179b
