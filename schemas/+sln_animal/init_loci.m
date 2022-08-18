function lmap = init_loci(do_insert)

loci = struct('locus_name',{},'description',{},'chromosome',{},'position',{});


%%% copy this and uncomment to add a new entry
% loci(end+1).locus_name = 
% loci(end).description = 
% loci(end).chromosome = 
% loci(end).position = 


%% CHAT
loci(end+1).locus_name = 'Chat';
loci(end).description = 'Enzyme that produces acetylcholine';
loci(end).chromosome = 14;
loci(end).position = 19.40;

%% ROSA
loci(end+1).locus_name = 'Rosa26';
loci(end).description = 'Locus for constitutive, ubiquitous expression';
loci(end).chromosome = 6;
loci(end).position = 52.73;

%% Igs7 - TIGRE (TITL iGluSnFr)
loci(end+1).locus_name = 'Igs7';
loci(end).description = 'Locus for constitutive, ubiquitous expression; intergenic-site 7, a TIGRE locus';
loci(end).chromosome = 9;
loci(end).position = 7.82; 

%% CCK
loci(end+1).locus_name = 'Cck';
loci(end).description = 'Neuropeptide and gastrointestinal hormone';
loci(end).chromosome = 9;
loci(end).position = 72.43;

%% Slc17a6
loci(end+1).locus_name = 'Slc17a6';
loci(end).description = 'Vesicular glutamate transporter, for loading of glutamate into synaptic vesicles';
loci(end).chromosome = 7;
loci(end).position = 32.78;

%% Ifi208
loci(end+1).locus_name = 'Ifi208';
loci(end).description = 'Interferon activated gene 208';
loci(end).chromosome = 1;
loci(end).position = 80.57;

%% Nos1
loci(end+1).locus_name = 'Nos1';
loci(end).description = 'Neuronal variant of nitric oxide synthase';
loci(end).chromosome = 5;
loci(end).position = 57.29;

%% PDGFR
loci(end+1).locus_name = 'PDGFRb';
loci(end).description = 'Platelet-derived growth factor receptor beta, critical for vascular development';
loci(end).chromosome = 18;
loci(end).position = 34.41;

%% Prss56
loci(end+1).locus_name = 'Prss56';
loci(end).description = 'Serine protease 56';
loci(end).chromosome = 1;
loci(end).position = 44.07;

%% Grm6
loci(end+1).locus_name = 'Grm6';
loci(end).description = 'glutamate receptor, metabotropic 6';
loci(end).chromosome = 11;
loci(end).position = 30.93;

%% Gad2
loci(end+1).locus_name = 'Gad2';
loci(end).description = 'glutamic acid decarboxylase 2';
loci(end).chromosome = 2;
loci(end).position = 15.15;

%% Camk2a
loci(end+1).locus_name = 'Camk2a';
loci(end).description = 'Calcium/calmodulin-dependent protein kinase II alpha';
loci(end).chromosome = 18;
loci(end).position = 34.41;

%% Tusc5
loci(end+1).locus_name = 'Trarg1';
loci(end).description = 'trafficking regulator of GLUT4 (SLC2A4) ';
loci(end).chromosome = 11;
loci(end).position = 45.98;

%% Opn5
loci(end+1).locus_name = 'Opn5';
loci(end).description = 'neuropsin';
loci(end).chromosome = 17;
loci(end).position = 19.65;

%% Camk2-tetO
loci(end+1).locus_name = 'Vipr2 / Wdr60 / Esyt2 / Ncapg2';
loci(end).description = 'location of CaMK2a-tetO insert';
loci(end).chromosome = 12;
loci(end).position = 62.6;


%% unknown
loci(end+1).locus_name = 'unknown';
loci(end).description = 'unknown locus';
loci(end).chromosome = nan;
loci(end).position = nan;


if nargin==0 || do_insert == true
    insert(sln_animal.GeneLocus,loci);
end
%% return map

lmap = containers.Map();

lmap('Ai14') = 'Rosa26';
lmap('CCK') = 'Cck';
lmap('CaMK2') = 'Vipr2 / Wdr60 / Esyt2 / Ncapg2';
lmap('ChAT') = 'Chat';
lmap('Cspg4') = 'Ifi208';
lmap('Gad2cre') = 'Gad2';
lmap('Gcamp') = 'Rosa26';
lmap('Gcamp6f') = 'Rosa26';
lmap('Grm6') = 'unknown';
lmap('RIK') = 'Rosa26';
lmap('Salsa6f') = 'Rosa26';
lmap('Scg2') = 'unknown';
lmap('TITL iGluSnfr') = 'Igs7';
lmap('Tusc5') = 'Trarg1';
lmap('Vglut C57') = 'Slc17a6';
lmap('Vglut C57bg') = 'Slc17a6';
lmap('Vglut cre-mixed') = 'Slc17a6';
lmap('Vglut-C57bg') = 'Slc17a6';
lmap('Vglut-Cre C57') = 'Slc17a6';
lmap('Vglut2-Cre mixed bg') = 'Slc17a6';
lmap('iGluSnfr') = 'Igs7';
lmap('nNos') = 'Nos1';
lmap('opn5cre') = 'Opn5';














