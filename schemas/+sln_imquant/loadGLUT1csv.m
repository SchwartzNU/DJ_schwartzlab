function [] = loadGLUT1csv(fname, drug_cond, in_vivo_flag)
if nargin < 3
    in_vivo_flag = false;
end
if nargin < 2
    drug_cond = '';
end

T = readtable(fname);
stack_image_files = unique(T.file_name);
L = length(stack_image_files);
fprintf('%d image stacks found in %s\n', L, fname);

for i=1:L
    cur_fname = stack_image_files{i};
    stack_key.image_fname = cur_fname;
    Tpart = T(strcmp(T.file_name,cur_fname),:);
    Ncells = height(Tpart);
    fprintf('%d cells found in %s\n', Ncells, cur_fname);
    
    %stuff for whole stack extracted from first cell
    stack_key.animal_id = Tpart.DJID(1);
    stack_key.age_at_exp = Tpart.Age_Months(1);
    if in_vivo_flag
        if strcmp(Tpart.Experimental_Condition{1},'Light Flicker')
            stack_key.light_condition_name = 'in vivo full-field flicker';
        else
            stack_key.light_condition_name = 'in vivo eye sutured';
        end
    else
        if strcmp(Tpart.Experimental_Condition{1},'Light Flicker')
            stack_key.light_condition_name = 'checkerboard flicker';
        else
            stack_key.light_condition_name = 'dark';
        end
    end
    if startsWith(Tpart.Eye{1},'L')
        stack_key.side = 'Left';
    else
        stack_key.side = 'Right';
    end
    if isempty(drug_cond)
        stack_key.drug_condition_name = 'control';
    else
        stack_key.drug_condition_name = drug_cond;
    end
    stack_key.stim_on_time = Tpart.Time_Condition(1);

    insert(sln_imquant.GLUT1Stack,stack_key);
    fprintf('%s stack inserted\n', cur_fname);

    %load each cell
    cell_key.animal_id = stack_key.animal_id;
    cell_key.side = stack_key.side;
    cell_key.image_fname = stack_key.image_fname;
    for c=1:Ncells
        key = cell_key;
        key.cell_id = c;
        if Tpart.eGFP_Value(c)==1
            key.gfp = 'T';
        else
            key.gfp = 'F';
        end
        if Tpart.In_Rip(c)==1
            key.in_rip = 'T';
        else
            key.in_rip = 'F';
        end
        if ~isnan(Tpart.Length_um(c))
            key.cell_length = Tpart.Length_um(c);
        end
        if ~isnan(Tpart.GluT1_Top_Integral(c))
            key.glut1_top_surf = Tpart.GluT1_Top_Integral(c);
        end
        if ~isnan(Tpart.GluT1_Bottom_Integral(c))
            key.glut1_bot_surf = Tpart.GluT1_Bottom_Integral(c);
        end
        if ~isnan(Tpart.GluT1_Middle_Integral(c))
            key.glut1_mid = Tpart.GluT1_Middle_Integral(c);
        end
        if ~isnan(Tpart.WGA_Top_Integral(c))
            key.membrane_top_surf = Tpart.WGA_Top_Integral(c);
        end
        if ~isnan(Tpart.WGA_Bottom_Integral(c))
            key.membrane_bot_surf = Tpart.WGA_Bottom_Integral(c);
        end
        if ~isnan(Tpart.WGA_Middle_Integral(c))
            key.membrane_mid = Tpart.WGA_Middle_Integral(c);
        end        

        insert(sln_imquant.GLUT1Cell,key);
    end

    fprintf('%d cells inserted\n', Ncells);
end
