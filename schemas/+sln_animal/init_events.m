function init_events(lmap, amap)
%% add old animal events to new database
event_fields = {'animal_id','user_name','date','time','entry_time','notes','event_id'};

%% Deceased
t = fetch(sl.AnimalEventDeceased,'*');
i = num2cell(1:numel(t));
[t.event_id] = i{:};

events = rmfield(t,setdiff(fieldnames(t), event_fields));
deceased = rmfield(t, setdiff(event_fields,'event_id'));


%% Assign protocol
t = fetch(sl.AnimalEventAssignProtocol,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
prot = rmfield(t, setdiff(event_fields,'event_id'));


%% Brain injection
t = fetch(sl.AnimalEventBrainInjection,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
brain_inj = rmfield(t, setdiff(event_fields,'event_id'));

%% Eye injection
t = fetch(sl.AnimalEventEyeInjection,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
eye_inj = rmfield(t, setdiff(event_fields,'event_id'));

%% IP injection
t = fetch(sl.AnimalEventIPinjection,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
ip_inj = rmfield(t, setdiff(event_fields,'event_id'));

%% Social Behavior session
t = fetch(sl.AnimalEventSocialBehaviorSession,'*');
old_ids = [t.event_id];

i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
behave = rmfield(t, setdiff(event_fields,'event_id'));

behave_stim = fetch(sl.AnimalEventSocialBehaviorSessionStimulus,'*');
new_ids = arrayfun(@(x) t(old_ids == x).event_id, [behave_stim.event_id],'uni',0);
[behave_stim(:).event_id] = new_ids{:};


%% Reserved for session
t = fetch(sl.AnimalEventReservedForSession,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
res_sess = rmfield(t, setdiff(event_fields,'event_id'));

%% Tag
t = fetch(sl.AnimalEventTag,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
tag = rmfield(t, setdiff(event_fields,'event_id'));

%% Reserved for Project
t = fetch(sl.AnimalEventReservedForProject,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
res_proj = rmfield(t, setdiff(event_fields,'event_id'));

%% Assign cage
t = fetch(sl.AnimalEventAssignCage,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

cage = rmfield(t, setdiff(event_fields,'event_id'));

cage = rmfield(cage,'room_number');
cn = cellfun(@(x) str2double(x(isstrprop(x,'digit'))), {cage(:).cage_number},'uni',0);
d = cellfun(@(x,y) ~strcmp(num2str(x),y), cn, {cage(:).cage_number});
[cage(:).cage_number] = cn{:};
[cage(strcmp({cage(:).cause},'')).cause] = 'unknown';

notes = cellfun(@(x) sprintf('Entered as cage number %s', x), {t(d).cage_number},'uni',0);
[t(d).notes] = notes{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));

%add notes when the cn has changed... fortunately there are no existing
%cage notes


%% Start by setting active breeding cages by establishing if the mice are alive
% breeding_pairs_struct = fetch(sln_animal.BreedingPair, '*');
% N = length(breeding_pairs_struct)
% for i=1:N
%     curPair = breeding_pairs_struct(i);
%     if ismember(curPair.male_id,[sln_animal.Animal.living.animal_id]) && ...
%             ismember(curPair.female_id,[sln_animal.Animal.living.animal_id])
%         
%     end
% end

% %% Pair breeders -> activate breeding pair
% pair_breeders_events_struct = rmfield(fetch(sl.AnimalEventPairBreeders  ,'*'), ...
%     {'event_id', 'cage_number', 'room_number', 'time'});
% N = length(pair_breeders_events_struct)
% for i=1:N
%     i
%     curEvent = pair_breeders_events_struct(i);
%     thisPair = sln_animal.BreedingPair & sprintf('male_id=%d',curEvent.male_id) ...
%         & sprintf('female_id=%d',curEvent.female_id);
%     
%     if thisPair.exists
%         curEvent = rmfield(curEvent,{'male_id','female_id'});
%         curEvent.source_id = fetch1(thisPair,'source_id');
%         curEvent
%         insert(sln_animal.ActivateBreedingPair,curEvent);
%     end
% end
% 
% %% Separate breeders -> deactivate breeding pair
% separate_breeders_events_struct = rmfield(fetch(sl.AnimalEventSeparateBreeders  ,'*'), ...
%     {'event_id', 'cage_number','new_cage_male','new_room_male', 'new_cage_female','new_room_female', 'time'});
% N = length(separate_breeders_events_struct)
% for i=1:N
%     i
%     curEvent = separate_breeders_events_struct(i);
%     thisPair = sln_animal.BreedingPair & sprintf('male_id=%d',curEvent.male_id) ...
%         & sprintf('female_id=%d',curEvent.female_id);
%     
%     if thisPair.exists
%         curEvent = rmfield(curEvent,{'male_id','female_id'});
%         curEvent.source_id = fetch1(thisPair,'source_id');
%         curEvent
%         insert(sln_animal.DeactivateBreedingPair,curEvent);
%     end
% end


%% Log births
t = fetch(sl.AnimalEventGaveBirth,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
births = rmfield(t, setdiff(event_fields,'event_id'));
births = rmfield(births,{'cage_number','number_of_pups'});

%% Log wean
t = fetch(sl.AnimalEventWeaned,'*');
i = num2cell(numel(events)+(1:numel(t)));
[t.event_id] = i{:};

%convert the cage numbers
cn = cellfun(@(x) str2double(x(isstrprop(x,'digit'))), {t(:).cage_number},'uni',0);
[t(:).cage_number] = cn{:};

%get the animal_ids by finding the associated birth event
[m, c] = fetchn(sl.AnimalEventGaveBirth,'animal_id','cage_number');
t2= unique(table(m,cellfun(@(x) str2double(x(isstrprop(x,'digit'))), c),'variablenames',{'animal_id','cage_number'}));
t = rmfield(table2struct(innerjoin(t2,struct2table(t))),'cage_number');

%ties 100%

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
weanings = rmfield(t, setdiff(event_fields,'event_id'));

%% now genotypes
t = fetch(sl.AnimalEventGenotyped * proj(sl.Animal,'genotype_name'),'*');
t([t(:).event_id]==1).genotype_status = 'carrier/carrier';
t([t(:).event_id]==2).genotype_status = 'carrier/carrier';
t([t(:).event_id]==3).genotype_status = 'carrier/carrier';
[t(strcmp({t(:).user_name},'Xin'))] = [];
[t(ismember([t(:).event_id],[478;479;480;481])).genotype_name] = deal('CaMK2/CCK');
t([t(:).event_id]==609).genotype_status = 'carrier/non-carrier/non-carrier/non-carrier';
t([t(:).event_id]==610).genotype_status = 'carrier/carrier/carrier/non-carrier';
t([t(:).event_id]==611).genotype_status = 'unknown/unknown';

t2 = t;

rn = cellfun(@(x) strrep(x,' x ', '/'), {t(:).genotype_name},'uni',0);
[t2(:).genotype_name] = rn{:};

rn = cellfun(@(x) strrep(strrep(strrep(x,'/WT',''),'/BLK6 bg',''),'/BLK6B',''), {t2(:).genotype_name},'uni',0);
[t2(:).genotype_name2] = rn{:};

good = cellfun(@(x,y) numel(split(x,'/')) == numel(split(y,'/')), {t2(:).genotype_name2}, {t2(:).genotype_status});

fixable = ~good & strcmp({t2(:).genotype_status}, 'carrier');
fix = cellfun(@(y) join(repmat("carrier", numel(split(y,'/')), 1),'/'), {t2(fixable).genotype_name2}, 'uni', 0);
[t2(fixable).genotype_status] = fix{:};
good = good | fixable;

unfixable = ~good & strcmp({t2(:).genotype_status}, 'non-carrier');
fix = cellfun(@(y) join(repmat("unknown", numel(split(y,'/')), 1),'/'), {t2(unfixable).genotype_name2}, 'uni', 0);
[t2(unfixable).genotype_status] = fix{:};
good = good | unfixable;

r = cellfun(@(x,y) [split(x,'/'), split(y,'/')], {t2(good).genotype_name2}, {t2(good).genotype_status},'uni', 0);
tmp = arrayfun(@(x,y) asgn_alleles(x{1},t(y)), r, find(good), 'uni', 0);
tmp = vertcat(tmp{:});

t = rmfield(tmp, {'genotype_status','genotype_name'});
i = num2cell(numel(events)+(1:numel(t)));

% update the event id, drop the genotype_status, translate genotype_name to
% locus_name, translate allele names

[t.event_id] = i{:};

% insert(sln_animal.GenotypeSource,{...
%     50, 'Unknown', 'genotype result of uncertain origin; for use with old data only';
%     51, 'Schwartz Lab', 'in-house genotyping';
%     52, 'Transnetyx', ''});

st = fetch(sln_animal.Animal, 'strain_name');
t = table2struct(innerjoin(struct2table(t), struct2table(st)));

%per Susan, via email/excel sheet:
[t(:).source_id] = deal(50);
[t(strcmp({t(:).strain_name},'VGluT2-Cre')).source_id] = deal(51);
[t(strcmp({t(:).strain_name},'VGluT2-Cre x GCaMP6f')).source_id] = deal(51);
[t(strcmp({t(:).strain_name},'Grm6-Cre x Salsa6f')).source_id] = deal(52);
[t(strcmp({t(:).strain_name},'VGluT2-Cre x Ai14')).source_id] = deal(51);
[t(strcmp({t(:).strain_name},'ChAT-Cre')).source_id] = deal(52);
[t(strcmp({t(:).strain_name},'Ai14')).source_id] = deal(51);
[t(strcmp({t(:).strain_name},'ChAT-Cre x Ai14')).source_id] = deal(52);
[t(strcmp({t(:).strain_name},'Tusc5-eGFP')).source_id] = deal(52);
[t(strcmp({t(:).strain_name},'VGluT2-Cre x ChAT-Cre x Ai14')).source_id] = deal(52);
[t(strcmp({t(:).strain_name},'Cspg4-Cre')).source_id] = deal(51);


t = rmfield(t,'strain_name');

events = cat(1,events,rmfield(t,setdiff(fieldnames(t), event_fields)));
genotyped = rmfield(t, setdiff(event_fields,'event_id'));

tmp = cellfun(@(x) lmap(x), {genotyped(:).locus_name},'uni',0);
[genotyped(:).locus_name] = tmp{:};

tmp = cellfun(@(x) amap(x), {genotyped(:).allele1},'uni',0);
[genotyped(:).allele1] = tmp{:};

n2 = ~cellfun(@(x) isscalar(x) && isnan(x), {genotyped(:).allele2});
tmp = cellfun(@(x) amap(x), {genotyped(n2).allele2},'uni',0);
[genotyped(n2).allele2] = tmp{:};


%% sorting and insertion
%order all of the events by entry time
[~, i] = sort(cellfun(@(x) datetime(x,'inputformat','yyyy-MM-dd HH:mm:ss'), {events(:).entry_time}));
[~,ii] = sort(i);
ii = num2cell(ii);

%convert the old event ids to the new ones... not the most efficent way to
%do this at all
ee = containers.Map([events(:).event_id], ii);

[events(:).event_id] = ii{:};
insert(sln_animal.AnimalEvent, events);

tii = arrayfun(@(x) ee(x), [behave.event_id],'uni',0);
[behave(:).event_id] = tii{:};
insert(sln_animal.SocialBehaviorSession, behave);

tii = arrayfun(@(x) ee(x), [behave_stim.event_id],'uni',0);
[behave_stim(:).event_id] = tii{:};
insert(sln_animal.SocialBehaviorSessionStimulus, behave_stim);

tii = arrayfun(@(x) ee(x), [births.event_id],'uni',0);
[births(:).event_id] = tii{:};
insert(sln_animal.Birth, births);

tii = arrayfun(@(x) ee(x), [brain_inj.event_id],'uni',0);
[brain_inj(:).event_id] = tii{:};
insert(sln_animal.BrainInjection, brain_inj);

tii = arrayfun(@(x) ee(x), [cage.event_id],'uni',0);
[cage(:).event_id] = tii{:};
insert(sln_animal.AssignCage, cage);

tii = arrayfun(@(x) ee(x), [deceased.event_id],'uni',0);
[deceased(:).event_id] = tii{:};
insert(sln_animal.Deceased, deceased);

tii = arrayfun(@(x) ee(x), [eye_inj.event_id],'uni',0);
[eye_inj(:).event_id] = tii{:};
insert(sln_animal.EyeInjection, eye_inj);

tii = arrayfun(@(x) ee(x), [ip_inj.event_id],'uni',0);
[ip_inj(:).event_id] = tii{:};
insert(sln_animal.IPInjection, ip_inj);

tii = arrayfun(@(x) ee(x), [prot.event_id],'uni',0);
[prot(:).event_id] = tii{:};
insert(sln_animal.AssignProtocol, prot);

tii = arrayfun(@(x) ee(x), [res_proj.event_id],'uni',0);
[res_proj(:).event_id] = tii{:};
insert(sln_animal.ReservedForProject, res_proj);

tii = arrayfun(@(x) ee(x), [res_sess.event_id],'uni',0);
[res_sess(:).event_id] = tii{:};
insert(sln_animal.ReservedForSession, res_sess);

tii = arrayfun(@(x) ee(x), [weanings.event_id],'uni',0);
[weanings(:).event_id] = tii{:};
insert(sln_animal.Weaned, weanings);

tii = arrayfun(@(x) ee(x), [tag.event_id],'uni',0);
[tag(:).event_id] = tii{:};
insert(sln_animal.Tag, tag);

tii = arrayfun(@(x) ee(x), [genotyped.event_id],'uni',0);
[genotyped(:).event_id] = tii{:};
insert(sln_animal.GenotypeResult, genotyped);

% for n=1:150
%     insert(sln_animal.GenotypeResult, genotyped((n-1)*10 +1 : n*10));
% end
% insert(sln_animal.GenotypeResult, genotyped(1501:end));

end

function s = asgn_alleles(result, s)
    s = repmat(s,size(result,1),1);
    for n=1:size(result,1)
        s(n).locus_name = result{n,1};
        if strcmp(result{n,1},'WT')
           disp('.'); 
        end
        if strcmp(result{n,2},'carrier')
            s(n).allele1 = result{n,1};
            s(n).allele2 = nan;
        elseif strcmp(result{n,2},'non-carrier')
            s(n).allele1 = 'WT';
            s(n).allele2 = 'WT';
        elseif strcmp(result{n,2},'het')
            s(n).allele1 = result{n,1};
            s(n).allele2 = 'WT';
        elseif strcmp(result{n,2},'homo')
            s(n).allele1 = result{n,1};
            s(n).allele2 = result{n,1};
        elseif strcmp(result{n,2},'unknown')
            s(n).allele1 = 'ambiguous';
            s(n).allele2 = nan;
            s(n).notes = 'Data entered incorrectly in V1 db';
        end
    end
end