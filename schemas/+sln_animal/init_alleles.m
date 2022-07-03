alleles = struct(...
    'allele_name',{},...
    'description',{});

%%% copy this and uncomment to add a new entry
% alleles(end+1).locus_name = 
% alleles(end).allele_name = 
% alleles(end).description = 
% alleles(end).is_wildtype = 
% alleles(end).source_id = 
% alleles(end).allele_id = 

%%% NOTE: source 1 = Jax

%% WT
alleles(end+1).allele_name = 'WT';
alleles(end).description = 'WT allele at any locus';

%% Ai14
alleles(end+1).allele_name = 'Ai14';
alleles(end).description = 'Cre-mediated tdTomato expression, floxed STOP cassette';
% alleles(end).source_id = 2;
% alleles(end).allele_id = 007914;

%% CCK
alleles(end+1).allele_name = 'CCK-Cre';
alleles(end).description = 'IRES';
% alleles(end).source_id = 2;
% alleles(end).allele_id = 012706;

%% VGluT2
alleles(end+1).allele_name = 'VGluT2-Cre';
alleles(end).description = 'IRES'; %, on a mixed C57bl/6,FVB,129S6 background';
% alleles(end).source_id = 2;
% alleles(end).allele_id = 016963;

% alleles(end+1).locus_name = 'Slc17a6';
% alleles(end).allele_name = 'VGluT2-Cre';
% alleles(end).description = 'IRES, on a pure C57bl/6 background';
% alleles(end).is_wildtype = 'F';
% alleles(end).source_id = 2;
% alleles(end).allele_id = 028863; %TODO: this was an error in the old DB?

%% CaMK2a
alleles(end+1).allele_name =  'Camk2a-tTA';
alleles(end).description = 'tet receptor at CamK2a locus';

%% iGluSnFR
alleles(end+1).allele_name =  'Ai87';
alleles(end).description = 'Cre and Tet-dependent iGluSnFR';

%% GCaMP6f
alleles(end+1).allele_name =  'GCaMP6f';
alleles(end).description = 'aka Ai95D, Cre-mediated GCaMP6f expression, floxed STOP cassette';
% alleles(end).source_id = 2;
% alleles(end).allele_id = 028865;

%% RIK
alleles(end+1).allele_name =  'RIK';
alleles(end).description = 'Cre-mediated, Tet-On expression of rtTA3 and (IRES) mKate2, floxed STOP cassette';
% alleles(end).source_id = 2;
% alleles(end).allele_id = 029633;

%% Cspg4
alleles(end+1).allele_name =  'Cspg4-Cre';
alleles(end).description = 'Binds to Cspg4 enhancer/promoter. Breeding through male germline leads to copy number loss.';

%% ChAT
alleles(end+1).allele_name = 'ChAT-Cre';
alleles(end).description = 'IRES';
% alleles(end).source_id = 2;
% alleles(end).allele_id = 006410;

%% GAD2
alleles(end+1).allele_name = 'Gad2-Cre';
alleles(end).description = 'GABAergic neurons';

%% nNOS
alleles(end+1).allele_name = 'nNOS-CreER';
alleles(end).description = 'Knock-in/knock-out, tamoxifen-induced, homozygotes are expected to exhibit severe abnormalities';

%% Grm6
alleles(end+1).allele_name = 'Grm6-Cre';
alleles(end).description = 'Located in ON bipolar cells and rod bipolar cells';

%% Opn5
alleles(end+1).allele_name = 'Opn5-Cre';
alleles(end).description = 'Neuropsin';
% alleles(end).source_id = 3;
% alleles(end).allele_id = 

%% PDGFR
alleles(end+1).allele_name = 'PDGFR-Cre';
alleles(end).description = 'Tamoxifen-induced, replaced STOP codon';

%% Prss56 KO
alleles(end+1).allele_name = 'Prss56-KO';
alleles(end).description = 'Prss56 knockout';

%% Prss56 Over
alleles(end+1).allele_name = 'Prss56-Over';
alleles(end).description = 'Prss56 overexpressor';

%% Salsa6f
alleles(end+1).allele_name =  'Salsa6f';
alleles(end).description = 'Cre-mediated expression of tdTomato/GCaMP6f fusion protein, floxed STOP cassette';
% alleles(end).source_id = 2;
% alleles(end).allele_id = 031968;

%% Scg2
alleles(end+1).allele_name =  'Scg2-tTA';
alleles(end).description = 'tTA under the secretogranin II promoter';

%% Tusc5
alleles(end+1).allele_name =  'Tusc5-eGFP';
alleles(end).description = 'GFP knock-in / knock out at Tusc5 locus';

%% Ambiguous
alleles(end+1).allele_name =  'Ambiguous';
alleles(end).description = 'Ambiguous genotyping result from V1 of database';

%%% end alleles
%% map from old genotype_name to list of new allele_ids
%TODO: this
allele_map = containers.Map();
% allele_map('Ai14') = [];d
% allele_map('Ai14/Vglut C57bg') = [];


%TODO: background??
