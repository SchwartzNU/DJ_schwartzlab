function [] = loadTransnetyxResultsFromFile(fname)
if nargin < 1
    [fname,path] = uigetfile('*.csv','Load .csv file from Transnetyx', ...
        [getenv('SERVER_ROOT') filesep 'AnimalLogs' filesep 'Genotyping Results' filesep 'Transnetyx results']);
else
    path = [];
end

date_str_part = extractBetween(fname,'_','.');
date_str_part = date_str_part{1};
parts = strsplit(date_str_part,'-');
date_str = sprintf('20%d-%02d-%02d',...
    str2double(parts{3}),str2double(parts{1}),str2double(parts{2}));

C = dj.conn;

T_results = readtable([path fname],'Delimiter',',');
T_decoder = readtable([getenv('SERVER') filesep 'AnimalLogs' filesep 'Transnetyx_decoder.xlsx']);
probeNames = T_results.Properties.VariableNames(6:end);

allTag = sln_animal.Animal.tagNumber([],true);
[gs,gi] = fetchn(sln_animal.GenotypeSource.active(),'source_name','source_id');
GenotypeSourceMap = containers.Map(gs, gi);
source_id = GenotypeSourceMap('Transnetyx');

for i=1:height(T_results)
    try
        key = struct;
        key.notes = sprintf('auto entered from file %s', fname);
        key.date = date_str;
        key.user_name = C.user;
        key.time = '00:00';
        key.source_id = source_id;
        
        result_strain = T_results.Strain{i};
        tag_id = T_results.Sample(i);
        tag_ind = find([allTag.tag_id]==tag_id);
        if isempty(tag_ind)
            fprintf('Error: live animal with tag %d not found.\n', tag_id);
        else
            key.animal_id = allTag(tag_ind).animal_id;
        end
        key_base = key;

        for j=1:length(probeNames)
            ind = find(strcmp(T_decoder.TransnetyxStrain, result_strain) & strcmp(matlab.lang.makeValidName(T_decoder.Code), probeNames{j}));
            if length(ind)==1                
                fprintf('row found for %s, %s\n', result_strain, probeNames{j})
                result_entry = T_results{i,j+5};
                result_entry = result_entry{1};
                key.locus_name = T_decoder.Locus{ind};
                if startsWith(result_entry, '+')
                    al1 = T_decoder{ind,"Allele1For_"};
                    al1 = al1{1};
                    if ~isempty(al1)
                        key.allele1 = al1;
                    end
                    al2 = T_decoder{ind,"Allele2For_"};
                    al2 = al2{1};
                    if ~isempty(al2)
                        key.allele2 = al2;
                    end
                elseif startsWith(result_entry, '-')
                    al1 = T_decoder{ind,"Allele1For__1"};
                    al1 = al1{1};
                    if ~isempty(al1)
                        key.allele1 = al1;
                    end
                    al2 = T_decoder{ind,"Allele2For__1"};
                    al2 = al2{1};
                    if ~isempty(al2)
                        key.allele2 = al2;
                    end
                end
                if isfield(key,'allele1') && isfield(key,'allele2') && isfield(key,'animal_id')
                    fprintf('Entering result for sample %d in row %d.\n', ...
                        T_results.Sample(i),i+1); 
                    key
                    sln_animal.add_event(key,'GenotypeResult');
                    key = key_base;
                end
            end
        end
               
    catch ME       
        fprintf('Result for sample %d in row %d of %s not entered.\n', ...
            T_results.Sample(i),i+1,fname);
        fprintf('Please enter manually if this is a valid result.\n');
        fprintf('Error: %s\n',ME.message);
    end

%    key
%    pause;
end



