%{
# GLUT3Cell
-> sln_imquant.GLUT3Stack
cell_id : int unsigned # unique cell id
---
gfp : enum('T','F')
in_rip : enum('T','F')
cell_length = NULL : float # microns
glut3_top_surf = NULL : int unsigned 
glut3_bot_surf = NULL : int unsigned 
glut3_mid = NULL : int unsigned 
membrane_top_surf = NULL : int unsigned 
membrane_bot_surf = NULL : int unsigned 
membrane_mid = NULL : int unsigned 
%}
classdef GLUT3Cell < dj.Manual
    methods(Static)

    end
end