%{
 # Projection testB (temporary)
item_id : int unsigned
 ---
(mynum) -> sl.ProjTestA(prim_num)

%}
classdef ProjTestB < dj.Manual
    
end

%-> sl.ProjTest.proj(user='sec_att')
%(mynum='prim_num')