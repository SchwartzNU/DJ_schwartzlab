%{
#Macro is a tree of tasks
macro_name : varchar(128) 
---
tissue_type : enum('Retina', 'Brain') #type of tissue
task_tree : blob #task tree serial(ized)
%}
classdef Macro < dj.Manual
    methods 
        function T = getTaskTree(self)
            T = getArrayFromByteStream(fetch1(self,'task_tree'));  
        end

        function printTaskTree(self)
             T = getTaskTree(self);
             disp(T.tostring);
        end

    end
end


