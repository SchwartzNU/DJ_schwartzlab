function bootDist = make_position_bootstrap_distribution(q, Nboot, chooseN, metricFunc)
%q is the input query
q_with_pos = q & 'side="Right" OR side="Left"';

%flip x coordinates for left eye
q_struct = fetch(q_with_pos, '*');
N_cells = length(q_struct)
metricVals = zeros(N_cells,1);
for i=1:N_cells
   if strcmp(q_struct(i).side, 'Left')
       q_struct(i).position_x = -q_struct(i).position_x;
   end   
   
   metricVals(i) = metricFunc(q_struct(i));  
end

bootDist = zeros(Nboot,chooseN);
for i=1:Nboot
    R = randperm(N_cells);
    bootDist(i,:) = metricVals(R(1:chooseN));
end




