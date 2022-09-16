function init_animals(strains_map)
old_animals = fetch(sl.Animal,'dob','sex', 'source', 'source_id','genotype_name');
[old_animals(:).strain_name] = old_animals(:).genotype_name;
old_animals = rmfield(old_animals,'genotype_name');

[old_animals(cellfun(@isempty,{old_animals(:).dob})).dob] = deal(nan);
% old_animals([old_animals.animal_id]==1024 | [old_animals.animal_id]==1019 | [old_animals.animal_id]==2011 | [old_animals.animal_id]==2012) = [];


%background -- assume no agouti mice in old db...
[bgn,~,ui] = unique({old_animals(:).strain_name});
mixed_bg = find(contains(bgn,'mixed'));
[old_animals(:).background_name] = deal('C57bl/6');
for bg = mixed_bg
    [old_animals(ui==bg).background_name] = deal('C57bl/6;FVB;129S6');
end
fathers([fathers.male_id] == 1187) = []; %this one appears to be an entry error

mothers = fetch((sl.AnimalEventAssignCage) * proj(sl.Animal&'sex="Female"'),'animal_id->female_id','cage_number->source_id') ;
fathers = fetch((sl.AnimalEventAssignCage) * proj(sl.Animal&'sex="Male"'),'animal_id->male_id','cage_number->source_id');

tm = struct2cell(rmfield(mothers,'event_id'))';
tm(:,2) = cellfun(@str2double, tm(:,2), 'UniformOutput', false);
[~,i,~] = unique(cell2mat(tm),'rows');
mothers = mothers(i);
% cn =  cellfun(@(x) x(~isletter(x)), {mothers(:).source_id},'uni',0);
% [mothers(:).source_id] = cn{:};

tm = struct2cell(rmfield(fathers,'event_id'))';
tm(:,2) = cellfun(@str2double, tm(:,2), 'UniformOutput', false);
[~,i,~] = unique(cell2mat(tm),'rows');
fathers = fathers(i);
% cn =  cellfun(@(x) x(~isletter(x)), {fathers(:).source_id},'uni',0);
% [fathers(:).source_id] = cn{:};

fathers([fathers.male_id] == 1187) = []; %this one appears to be an entry error

% t = join(struct2table(old_animals),struct2table(rmfield(mothers,'event_id')),'keys','source_id');


t = outerjoin(struct2table(old_animals),struct2table(rmfield(mothers,'event_id')),'mergekeys',true,'type','left');
t = outerjoin(t,struct2table(rmfield(fathers,'event_id')),'mergekeys',true,'type','left');

t(t.animal_id==1054,'male_id') = {1064}; %not picked up because the male has a leading "MJ" in the cage number
t(t.animal_id==1055,'male_id') = {1064}; %as above
t(t.animal_id>867 & t.animal_id<872,'male_id') = {787,787,787,787}'; %as above
t(t.animal_id>867 & t.animal_id<872,'female_id') = {786,786,786,786}'; %as above
%animal_id=790: source_id is the jax strain


t = sortrows(t,'animal_id');

% breeding_pairs = table2struct(sortrows(unique(t(~isnan(t.male_id) & ~isnan(t.female_id),{'strain_name','background_name','male_id','female_id'})),'female_id'));
[~,i] = unique(t(~isnan(t.male_id) & ~isnan(t.female_id),{'male_id','female_id'}));
breeding_pairs = table2struct(sortrows(t(i,{'strain_name','background_name','male_id','female_id'}),'female_id'));

[breeding_pairs.source_id] = subsref(num2cell(1000+(1:numel(breeding_pairs))),substruct('{}',{1:numel(breeding_pairs)}));
new_animals = rmfield(old_animals, {'source', 'source_id'});


%source
old_animals([old_animals.animal_id]==1520).source = 'vendor'; %these appear to be mislabelled as "other"
old_animals([old_animals.animal_id]==1521).source = 'vendor'; %nothing ever came of these mice so... oh well?


vendor_ind = strcmp({old_animals.source}, 'vendor');
[new_animals(vendor_ind).source_id] = deal(1); %vendor id for Jax

other_lab_ind = find(strcmp({old_animals.source}, 'other lab'));
[old_animals([old_animals.animal_id]==2038 | [old_animals.animal_id]==2039).source_id] = deal('Fawzi'); %entry error


[u, ~, i] = unique({old_animals(other_lab_ind).source_id});

[new_animals(other_lab_ind(any(i == find(contains(u,'CCHMC')),2))).source_id] = deal(105); %collaborator id for Richard Lang
[new_animals(other_lab_ind(any(i == find(contains(u,'Fawzi')),2))).source_id] = deal(104); %...
[new_animals(other_lab_ind(any(i == find(contains(u,'ington')),2))).source_id] = deal(101);
[new_animals(other_lab_ind(any(i == find(contains(u,'Krizaj')),2))).source_id] = deal(108);
[new_animals(other_lab_ind(any(i == find(contains(u,'NEI')),2))).source_id] = deal(103);
[new_animals(other_lab_ind(any(i == find(contains(u,'Nair')),2))).source_id] = deal(102);
[new_animals(other_lab_ind(any(i == find(contains(u,'Yongling')),2))).source_id] = deal(106);

[new_animals(other_lab_ind(any(i == find(contains(u,'Fawzi')),2))).source_id] = deal(104); %...


% handle unknown animals
[new_animals(strcmp({old_animals(:).source},'unknown')).source_id] = deal(nan);

breeding_ind = strcmp({old_animals.source}, 'breeding');
[new_animals(breeding_ind' & (isnan(t.female_id) | isnan(t.male_id))).source_id] = deal(nan);

%% strains

strain_names = cellfun(@(x) strains_map(x), {old_animals(:).strain_name},'uni',0)';
[new_animals(:).strain_name] = strain_names{:};

strain_names = cellfun(@(x) strains_map(x), {breeding_pairs(:).strain_name},'uni',0)';
[breeding_pairs(:).strain_name] = strain_names{:};

%%
insertable = [];
inserted_breeders = false(size(breeding_pairs));
sln_animal.Source().insert(rmfield(breeding_pairs,{'strain_name','male_id','female_id','background_name'}));
for animal = new_animals'
    if isempty(animal.source_id)
        thisBreeder = ([breeding_pairs.male_id] == t(t.animal_id == animal.animal_id,:).male_id) & ([breeding_pairs.female_id] == t(t.animal_id == animal.animal_id,:).female_id);
        animal.source_id = breeding_pairs(thisBreeder).source_id;
        if ~inserted_breeders(thisBreeder)
            % we need to insert this animal's breeders
            insert(sln_animal.Animal, insertable);
            insertable_breeders = ismember([breeding_pairs.male_id],[insertable.animal_id]) & ismember([breeding_pairs.female_id],[insertable.animal_id]);
            insert(sln_animal.BreedingPair, breeding_pairs(insertable_breeders' & ~inserted_breeders));

            inserted_breeders = inserted_breeders | insertable_breeders';
            insertable = [];

        end  
    end
    insertable = cat(1,insertable,animal);
end
insert(sln_animal.Animal, insertable);
            
% insertable_breeders = ismember([breeding_pairs.male_id],[insertable.animal_id]) & ismember([breeding_pairs.female_id],[insertable.animal_id]);
insert(sln_animal.BreedingPair, breeding_pairs(~inserted_breeders));





