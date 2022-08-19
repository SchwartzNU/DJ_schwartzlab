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
            S = hlp_deserialize(fetch1(self,'task_tree'));  
            S = S.Node{1};
            T = tree(S.Node{1});
            for i=2:length(S.Node)
                T = T.addnode(S.Parent(i), S.Node{i});
            end
        end

        function printTaskTree(self)
             T = getTaskTree(self);
             disp(T.tostring);
        end
    end
end


