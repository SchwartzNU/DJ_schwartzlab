%{
 # Projection testB (temporary)
item_id : int unsigned
 ---
(mynum) -> sl_test.ProjTestA(prim_num)

%}
classdef ProjTestB < dj.Manual
    
end

%-> sl_test.ProjTest.proj(user='sec_att')
%(mynum='prim_num')