%% drop tables
safemode = dj.config('safemode');
dj.config('safemode',false);
drop(sln_animal.Background);
drop(sln_animal.Source);
drop(sln_animal.CageRoom);
drop(sln_animal.Species);
drop(sln_animal.GeneLocus);

%% repopulate tables
insert(sln_animal.Background,{'C57bl/6', 'mouse', 'The most widely used inbred strain of mice'; 'Agouti', 'mouse', 'Spontaneous mutation from the C57bl/6 line'});
insert(sln_animal.Source, {1;2;3;4;});
insert(sln_animal.Vendor,...
    {2, 'Jackson Laboratory', 'jax.org';
    3, 'University of Washington', 'uw.edu';
    4, 'Cincinnati Children''s Hospital Medical Center', 'cincinnatichildrens.org'}...
    );

%%% Animals
sln_animal.init_animals;

%%% Cage
assign_cage = fetch(sl.AnimalEventAssignCage,'*');
cage = { assign_cage(:).cage_number; assign_cage(:).room_number; assign_cage(:).cause}';
[c_u,~,c_i] = unique(cage(:,1));
[r_u,~,r_i] = unique(cage(:,2));
b_l = strcmp(cage(:,3),'set as breeder');
cage_u = unique([c_i, r_i, b_l],'rows');
cage_u = [c_u(cage_u(:,1)), r_u(cage_u(:,2)), num2cell(cage_u(:,3))];
% cage_u has the putative entries for sln_animal.Cage, but some bad ones
cage_u(cellfun(@isempty,cage_u(:,1)),:) = []; %no cage number
cage_u(contains(cage_u(:,1),'temp','ignorecase',true),:) = []; %fake cages
%TODO: more filtering of cages...


%%% Genetics
%construct a mapping of old genotypes to new system...
init_alleles;
init_loci;
% gene_info = containers.Map();
% gene_info('Ai14') = alleles;



%% clean up
dj.config('safemode',safemode);