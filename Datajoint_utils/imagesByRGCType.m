function imageTable = imagesByRGCType(q)
allTypes = fetchn(q,'cell_type');
N = length(allTypes);

typesU = unique(allTypes);
Ntypes = length(typesU);

imageTable = table('Size',[Ntypes, 7], ...
    'VariableTypes',{'string', 'uint16', 'uint16', 'uint16', 'uint16', 'cellstr', 'cellstr'}, ...
    'VariableNames', {'RGC_type', 'N_phys', 'N_validated', 'N_confocal', 'N_2P', 'Confocal_images', '2P_images'});

q_struct = fetch(q);

for i=1:Ntypes
   curType = typesU{i};
   ind = strcmp(allTypes,curType); 
   
   imageTable(i,'RGC_type') = {curType};
   imageTable(i,'N_phys') = {sum(ind)};
   
   temp_query = sl_mutable.CellTypeValidation & q_struct(ind) & 'external_validation="T"';   
   imageTable(i,'N_validated') = {temp_query.count};
   
   query_confocal = sl_mutable.CellTypeValidation & q_struct(ind) & 'validation_type="confocal image"';   
   imageTable(i,'N_confocal') = {query_confocal.count};
   
   query_2P = sl_mutable.CellTypeValidation & q_struct(ind) & 'validation_type="2P image"';   
   imageTable(i,'N_2P') = {query_2P.count};
      
   if imageTable{i,'N_confocal'} > 0
       imageTable(i,'Confocal_images') = {char(fetchn(query_confocal, 'cell_id'))};
   end
   
   if imageTable{i,'N_2P'} > 0
          imageTable(i,'2P_images') = {char(fetchn(query_2P, 'cell_id'))};   
   end
   
end

