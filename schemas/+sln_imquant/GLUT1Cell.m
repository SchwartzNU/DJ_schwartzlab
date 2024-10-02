%{
# GLUT1Cell
-> sln_imquant.GLUT1Stack
cell_id : int unsigned # unique cell id
---
gfp : enum('T','F')
in_rip : enum('T','F')
cell_length = NULL : float # microns
glut1_top_surf = NULL : int unsigned 
glut1_bot_surf = NULL : int unsigned 
glut1_mid = NULL : int unsigned 
membrane_top_surf = NULL : int unsigned 
membrane_bot_surf = NULL : int unsigned 
membrane_mid = NULL : int unsigned 
%}
classdef GLUT1Cell < dj.Manual
    methods(Static)

    end
end