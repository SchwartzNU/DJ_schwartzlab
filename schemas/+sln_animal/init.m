%% drop tables
safemode = dj.config('safemode');
dj.config('safemode',false);
drop(sln_animal.Background);
drop(sln_animal.Source);
drop(sln_animal.CageRoom);
drop(sln_animal.Species);
drop(sln_animal.GeneLocus);
drop(sln_animal.Allele);
drop(sln_animal.BrainArea);
drop(sln_animal.Cage);
drop(sln_animal.AnimalProtocol);


%% backgrounds and sources
insert(sln_animal.Background,...
    {'C57bl/6', 'mouse', 'The most widely used inbred strain of mice';
    'Agouti', 'mouse', 'Spontaneous mutation from the C57bl/6 line';
    'C57bl/6;FVB;129S6', 'mouse', 'A mixed background with black, agouti, and albino coat colors'});
insert(sln_animal.Source, num2cell(1:6)');
insert(sln_animal.Source, num2cell(50:52)');
insert(sln_animal.Source, num2cell(100:109)');
insert(sln_animal.Vendor,{...
    1, 'Jackson Laboratory';
    2, 'Sigma';
    3, 'Addgene';
    4, 'Invitrogen';
    5, 'Envigo';
    6, 'Duke Viral Vector Core';
    });
insert(sln_animal.GenotypeSource,{...
    50, 'Unknown', 'genotype result of uncertain origin; for use with old data only';
    51, 'Schwartz Lab', 'in-house genotyping';
    52, 'Transnetyx', ''});
insert(sln_animal.Collaborator, {...
    100, 'Schwartz Lab', 'NU'; 
    101, 'Rachel Wong', 'U. Washington';
    102, 'Sai Nair', 'UCSF';
    103, 'Tudor Badea', 'U. Transylvania';
    104, 'Amani Fawzi', 'NU';
    105, 'Richard Lang', 'CCHMC';
    106, 'Yongling Zhu', 'NU';
    107, 'Tiffany Schmidt', 'NU';
    108, 'David Krizaj', 'U. Utah';
    109,'Nathan Gianneschi', 'NU';
    });

%% Genetics
%construct a mapping of old genotypes to new system...
amap = sln_animal.init_alleles;
lmap = sln_animal.init_loci;

%% Strains
strains_map = {...
'Ai14','Ai14'; 'RIK', 'RIK'; 'Salsa6f','Salsa6f-Cre'; 'TITL iGluSnfr', 'TITL iGluSnFR'; 'WT', 'WT';
'Ai14/Vglut C57/ChAT', 'VGluT2-Cre x ChAT-Cre x Ai14';
'Ai14/Vglut C57bg', 'VGluT2-Cre x Ai14';
'CCK', 'CCK-Cre';
'CCK/Gcamp6f', 'CCK-Cre x GCaMP6f';
'CCK/RIK', 'CCK-Cre x RIK';
'CCK/RIK/TITL iGluSnfr', 'CCK-Cre x RIK x TITL iGluSnFR';
'CCK/WT', 'CCK-Cre';
'CaMK2 x iGluSnfr x CCK', 'CCK-Cre x CaMK2a-tTA x TITL iGluSnFR';
'CaMk2 x iGluSnfr', 'CaMK2a-tTA x TITL iGluSnFR';
'ChAT' ,'ChAT-Cre';
'ChAT/Ai14', 'ChAT-Cre x Ai14';
'Cspg4', 'Cspg4-Cre';
'Cspg4/Gcamp6f', 'Cspg4-Cre x GCaMP6f';
'Diabetic', 'WT';
'Diabetic - Sham', 'WT';
'Gad2cre/Ai14', 'Gad2-Cre x Ai14';
'Gcamp/Cspg4/nNos', 'nNOS-CreER x Cspg4-Cre x GCaMP6f';
'Gcamp6f', 'GCaMP6f';
'Gcamp6f x Grm6', 'Grm6-Cre x GCaMP6f';
'Gcamp6f x Grm6 x TITL iGluSnfr', 'Grm6-Cre x GCaMP6f x TITL iGluSnFR';
'Gcamp6f x RIK/Grm6/TITL iGluSnfr', 'Grm6-Cre x RIK x TITL iGluSnFR x GCaMP6f';
'Gcamp6f x Vglut cre-mixed', 'VGluT2-Cre x GCaMP6f';
'Grm6 cre', 'Grm6-Cre';
'Grm6/TITL iGluSnfr', 'Grm6-Cre x TITL iGluSnFR';
'Opn5', 'Opn5-Cre';
'PDGFR beta ER', 'PDGFRb-CreER';
'PDGFR beta ER/Gcamp6f', 'PDGFRb-CreER x GCaMP6f';
'Prss56', 'Prss56-KO';
'Prss56_over/WT', 'Prss56-OE';
'RIK/Grm6/TITL iGluSnfr', 'Grm6-Cre x RIK x TITL iGluSnFR';
'Salsa6f x CCK','CCK-Cre x Salsa6f-Cre';
'Salsa6f x Grm6','Grm6-Cre x Salsa6f-Cre';
'Scg2 x TITL iGluSnfr x CCK', 'CCK-Cre x Scg2-tTA x TITL iGluSnFR';
'Scg2 x iGluSnfr', 'Scg2-tTA x TITL iGluSnFR';
'TITL iGluSnfr/RIK', 'RIK x TITL iGluSnFR';
'Tusc5', 'Tusc5-eGFP';
'Vglut-C57bg/WT', 'VGluT2-Cre';
'Vglut-Cre C57/BLK6 bg', 'VGluT2-Cre';
'Vglut-Cre C57/BLK6B x Salsa6f', 'VGluT2-Cre x Salsa6f-Cre';
'Vglut2-Cre mixed bg', 'VGluT2-Cre';
'nNos creER', 'nNOS-CreER';
'nNos/WT', 'nNOS-CreER';
'opn5cre/WT','Opn5-Cre'};

strains_map = containers.Map(strains_map(:,1), strains_map(:,2));

strains = struct('strain_name',unique(strains_map.values()),'background_name','C57bl/6');


strains(end+1).strain_name = 'VGluT2-Cre x GCaMP6f';
strains(end).background_name='C57bl/6;FVB;129S6';
[strains.species_name] = deal('mouse');

strains(end+1).strain_name = 'VGluT2-Cre';
strains(end).background_name='C57bl/6;FVB;129S6';
[strains.species_name] = deal('mouse');

sln_animal.Strain().insert(strains)

%% Strain genotypes
strain_gt= cell2mat(cellfun(@(x) struct('strain_name',x, 'allele_name', strsplit(x,' x '),'background_name','C57bl/6'), unique(strains_map.values()), 'UniformOutput', false));
strain_gt(end+1).strain_name = 'VGluT2-Cre x GCaMP6f';
strain_gt(end).allele_name = 'VGluT2-Cre';
strain_gt(end).background_name = 'C57bl/6;FVB;129S6';

strain_gt(end+1).strain_name = 'VGluT2-Cre x GCaMP6f';
strain_gt(end).allele_name = 'GCaMP6f';
strain_gt(end).background_name = 'C57bl/6;FVB;129S6';

strain_gt(end+1).strain_name = 'VGluT2-Cre';
strain_gt(end).allele_name = 'VGluT2-Cre';
strain_gt(end).background_name = 'C57bl/6;FVB;129S6';

insert(sln_animal.StrainAllele, strain_gt);

%% Strain sources
strain_src = struct('strain_name',{},'source_id',{},'strain_id',{});

%vendor strains
strain_src(end+1).strain_name = 'WT';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '000664';

strain_src(end+1).strain_name = 'CCK-Cre';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '012706';

strain_src(end+1).strain_name = 'VGluT2-Cre';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '028863';

strain_src(end+1).strain_name = 'RIK';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '029633';

strain_src(end+1).strain_name = 'Salsa6f-Cre';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '031968';

strain_src(end+1).strain_name = 'nNOS-CreER';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '014541';

strain_src(end+1).strain_name = 'Ai14';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '007914';

strain_src(end+1).strain_name = 'ChAT-Cre';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '006410';

strain_src(end+1).strain_name = 'Cspg4-Cre';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '008533';

strain_src(end+1).strain_name = 'GCaMP6f';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '028865';

strain_src(end+1).strain_name = 'PDGFRb-CreER';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '029684';

strain_src(end+1).strain_name = 'TITL iGluSnFR';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '026260';


%collaborator strains

strain_src(end+1).strain_name = 'Grm6-Cre';
strain_src(end).strain_id = 'https://doi.org/10.1073/pnas.1510483112';
strain_src(end).source_id = 101;

strain_src(end+1).strain_name = 'Prss56-KO';
strain_src(end).source_id = 102;

strain_src(end+1).strain_name = 'Prss56-OE';
strain_src(end).source_id = 102;

strain_src(end+1).strain_name = 'Tusc5-eGFP';
strain_src(end).source_id = 103;

strain_src(end+1).strain_name = 'Opn5-Cre';
strain_src(end).source_id = 105;

strain_src(end+1).strain_name = 'CaMK2a-tTA x TITL iGluSnFR';
strain_src(end).source_id = 106;

strain_src(end+1).strain_name = 'Scg2-tTA x TITL iGluSnFR';
strain_src(end).source_id = 106;

[strain_src(:).background_name] = deal('C57bl/6');

strain_src(end+1).strain_name = 'VGluT2-Cre';
strain_src(end).background_name = 'C57bl/6;FVB;129S6';
strain_src(end).source_id = 1;
strain_src(end).strain_id = '016963';

% missing:  opn4-egfp from tiffany, trpv4 from krizaj?
sln_animal.StrainSource().insert(strain_src)

%% Animals
sln_animal.init_animals(strains_map);

s = load('schemas\+sln_animal\full_backup_081522.mat').s;
s.AnimalExternal(contains({s.AnimalExternal(:).external_info},'test')) = [];
insert(sln_animal.AnimalExternal, s.AnimalExternal);

%% Cages
cage = struct2table(fetch(sl.AnimalEventAssignCage,'*','ORDER BY date ASC'));
cage.cage_number = cellfun(@(x) str2double(x(isstrprop(x,'digit'))), cage.cage_number);
cage = sortrows(cage,{'cage_number','date'});

%only consider a cage assignment a cage move if the room number changed
no_move = arrayfun(@(x) cage.cage_number(x-1) == cage.cage_number(x) && strcmp(cage.room_number(x-1),cage.room_number(x)),2:size(cage,1));
cage(no_move,:) = [];

cn = unique(cage.cage_number(~isnan(cage.cage_number)));
insert(sln_animal.Cage, num2cell(cn));

cage = rmfield(table2struct(cage), {'time','cause','notes','event_id','animal_id'});
insert(sln_animal.CageAssignRoom,cage);

%% Substances
substances = fetch(sl.InjectionSubstance,'*');
[substances(contains({substances(:).source},'igma')).source_id] = deal(2);
[substances(contains({substances(:).source},'ddgene')).source_id] = deal(3);

[substances(contains({substances(:).source},'uke')).source_id] = deal(6);
[substances(contains({substances(:).source},'itrogen')).source_id] = deal(4);
[substances(contains({substances(:).source},'alk')).source_id] = deal(3);
[substances(contains({substances(:).source},'Teklad')).source_id] = deal(5);

[substances(contains({substances(:).source},'Nair')).source_id] = deal(102);
[substances(contains({substances(:).source},'Gianneschi')).source_id] = deal(109);
[substances(contains({substances(:).source},'Lang')).source_id] = deal(105);
[substances(contains({substances(:).source},'Amani')).source_id] = deal(104);

[substances(contains({substances(:).source},'made in lab')).source_id] = deal(100);

substances(contains({substances(:).source},'dog food')) = [];
substances(contains({substances(:).source},'None')) = [];
substances(contains({substances(:).source},'Fiction')) = [];

[substances(contains({substances(:).source},'?')).source_id] = deal(3);
[substances(contains({substances(:).catalog_number},'?')).catalog_number] = deal('114472');

insert(sln_animal.InjectionSubstance, rmfield(substances, {'source'}));

%% Other
insert(sln_animal.BrainArea, fetch(sl.BrainArea,'*'));
insert(sln_animal.AnimalProtocol, fetch(sl.AnimalProtocol,'*'));

%% Events
sln_animal.init_events(lmap, amap);

%when were these injections done?
f = fetch(sl.Animal & 'genotype_name = "Diabetic"','dob');
tmp = cellfun(@(x) datestr(datetime(x,'inputformat','yyyy-MM-dd') + duration(24*7*3,0,0),'yyyy-mm-dd'), {f(:).dob},'uni',0);
[f(:).date] = tmp{:};
[f(:).user_name] = deal('Unknown');
[f(:).substance_id] = deal(21);
[f(:).concentration] = deal(0);
f = rmfield(f,'dob');

e_id = insert(sln_animal.AnimalEvent, f);
insert(sln_animal.IPInjection, e_id);

f = fetch(sl.Animal & 'genotype_name = "Diabetic - sham"','dob');
tmp = cellfun(@(x) datestr(datetime(x,'inputformat','yyyy-MM-dd') + duration(24*7*3,0,0),'yyyy-mm-dd'), {f(:).dob},'uni',0);
[f(:).date] = tmp{:};
[f(:).user_name] = deal('Unknown');
[f(:).substance_id] = deal(17);
[f(:).concentration] = deal(0);
f = rmfield(f,'dob');

e_id = insert(sln_animal.AnimalEvent, f);
insert(sln_animal.IPInjection, e_id);



%% Genotype inference
sln_animal.init_genotypes;

%% clean up
dj.config('safemode',safemode);

