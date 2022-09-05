%{
# A pair of animals for breeding
-> sln_animal.Source
---
-> sln_animal.Strain
(male_id) -> sln_animal.Animal
(female_id) -> sln_animal.Animal
%}

classdef BreedingPair < dj.Manual
    methods(Static)
        function q = breeding_cages()
            q = sln_animal.Cage * proj(sln_animal.AnimalEvent * sln_animal.AssignCage, 'lead(date) over(partition by animal_id order by date)->end_date', 'date->start_date','animal_id','cage_number') * proj(sln_animal.Animal,'sex');
            q = proj(q & 'sex="Female"', 'animal_id->female_id','event_id->female_event','start_date->female_start','end_date->female_end') * proj(q & 'sex="Male"', 'animal_id->male_id','event_id->male_event','start_date->male_start','end_date->male_end');
            
            q = aggr(sln_animal.BreedingPair, q & '(male_start < female_end OR female_end is null) AND (female_start < male_end OR male_end is null)', '*', 'convert(substring(max(concat(female_start, cage_number)), 11), unsigned)->cage_number','if(max(female_start)>max(male_start),max(female_start),max(male_start))->pair_date');
            q = q & 'pair_date is not null'; %NOTE: shouldn't be necessary if breeding pairs table is up to date...
        end
        
        function q = active_animals()
            cage = sln_animal.BreedingPair.breeding_cages();
            
            %remove cages where the female is deceased
            deceased = sln_animal.Animal * sln_animal.AnimalEvent * sln_animal.Deceased;
            
            q = cage - proj(deceased,'animal_id->female_id');
            
            %remove cages where the female is retired and the male is deceased
            female = (sln_animal.Animal & 'sex="Female"') & (sln_animal.AnimalEvent * (sln_animal.ReservedForProject & 'project_name="Breeding" OR project_name="Former breeder"'));
            female_ev = (sln_animal.Animal & 'sex="Female"') * sln_animal.AnimalEvent * (sln_animal.ReservedForProject & 'project_name="Breeding" OR project_name="Former breeder"');
            female_status = aggr(female, female_ev, 'substring(max(concat(date, entry_time, project_name)), 30)->project_name', 'animal_id->female_id'); %"scalar-aggregate reduction"
            
            q = q - (proj(deceased,'animal_id->male_id') & proj(female_status & 'project_name="Former breeder"'));
            
            % Remove cages where the male is absent and the female is
            % retired
%             male_current = proj(cage *  proj(sln_animal.AssignCage.current * sln_animal.Cage,'animal_id->male_id','cage_number'));
            q = q & (proj(female_status & 'project_name="Breeding"') & proj(sln_animal.AssignCage.current,'animal_id->male_id','cage_number'));

            q = sln_animal.Animal & (proj(q,'male_id->animal_id','source_id->male_source') | proj(q,'female_id->animal_id','source_id->female_source'));
            
        end
        
        function q = active_pairs()
            cage = sln_animal.BreedingPair.breeding_cages();
            
            %remove cages where the female is deceased
            deceased = sln_animal.Animal * sln_animal.AnimalEvent * sln_animal.Deceased;
            
            q = cage - proj(deceased,'animal_id->female_id');
            
            %remove cages where the female is retired and the male is deceased
            female = (sln_animal.Animal & 'sex="Female"') & (sln_animal.AnimalEvent * (sln_animal.ReservedForProject & 'project_name="Breeding" OR project_name="Former breeder"'));
            female_ev = (sln_animal.Animal & 'sex="Female"') * sln_animal.AnimalEvent * (sln_animal.ReservedForProject & 'project_name="Breeding" OR project_name="Former breeder"');
            female_status = aggr(female, female_ev, 'substring(max(concat(date, entry_time, project_name)), 30)->project_name', 'animal_id->female_id'); %"scalar-aggregate reduction"
            
            q = q - (proj(deceased,'animal_id->male_id') & proj(female_status & 'project_name="Former breeder"'));
            
            % Remove cages where the male is absent and the female is
            % retired
%             male_current = proj(cage *  proj(sln_animal.AssignCage.current * sln_animal.Cage,'animal_id->male_id','cage_number'));
            q = q & (proj(female_status & 'project_name="Breeding"') & proj(sln_animal.AssignCage.current,'animal_id->male_id','cage_number'));

            
        end

        function ids = active_animal_ids(sex)
            if nargin < 1
                sex = 'both';
            end
            q = sln_animal.BreedingPair.active_animals();
            if ~q.exists
                ids = [];
                return;
            end
            ids = fetchn(q,'animal_id');
        end
        
        function D = breeders_table()
            
            % ever paired
            cage = sln_animal.BreedingPair.breeding_cages();
            
            female = (sln_animal.Animal & 'sex="Female"') & (sln_animal.AnimalEvent * (sln_animal.ReservedForProject & 'project_name="Breeding" OR project_name="Former breeder"'));
            female_ev = (sln_animal.Animal & 'sex="Female"') * sln_animal.AnimalEvent * (sln_animal.ReservedForProject & 'project_name="Breeding" OR project_name="Former breeder"');
            female_status = aggr(female, female_ev, 'substring(max(concat(date, entry_time, project_name)), 30)->project_name', 'animal_id->female_id'); %"scalar-aggregate reduction"
                        
            % litter info -- litter counts, litter dates, wean counts, next
            % wean date
            dd = aggr(sln_animal.BreedingPair, cage * proj(sln_animal.Animal,'animal_id->female_id')* proj(sln_animal.AnimalEvent * sln_animal.Birth, 'animal_id->female_id','date->birth_date') & 'birth_date > pair_date', 'count(birth_date)->litter_count', 'group_concat(birth_date separator ", ")->litter_dates', 'IF(datediff(now(), max(birth_date))<=22, date_add(max(birth_date), interval 22 day), "") -> next_wean');
            ee = aggr(sln_animal.BreedingPair, cage * proj(sln_animal.Animal,'animal_id->female_id')* proj(sln_animal.AnimalEvent * sln_animal.Weaned, 'animal_id->female_id','date->weaned_date','number_of_pups->wean_count') & 'weaned_date > pair_date', 'group_concat(wean_count separator ", ")->wean_counts');

            cc = dd * cage * ee;
            % add the room number
            rn = aggr(sln_animal.Cage, sln_animal.CageAssignRoom, 'substring(max(concat(date, room_number)), 11)->room_number'); %"scalar-aggregate reduction"
            q = proj(sln_animal.BreedingPair,'strain_name','male_id','female_id') * aggr(sln_animal.BreedingPair, cc, 'any_value(cage_number) -> cage_number', 'any_value(pair_date) -> pair_date', 'any_value(litter_count)->litter_count', 'any_value(litter_dates)->litter_dates', 'any_value(wean_counts)->wean_counts', 'any_value(next_wean)->next_wean') * rn;
            
            %remove cages where the female is deceased
            deceased = sln_animal.Animal * sln_animal.AnimalEvent * sln_animal.Deceased;
            
            q = q - proj(deceased,'animal_id->female_id');
            
            q = q - (proj(deceased,'animal_id->male_id') & proj(female_status & 'project_name="Former breeder"'));
            
            % Remove cages where the male is absent and the female is
            % retired
            q = q & (proj(female_status & 'project_name="Breeding"') & proj(sln_animal.AssignCage.current,'animal_id->male_id','cage_number'));

            % add ages, strains, genotypes
            D = q * proj(sln_animal.Animal * sln_animal.GenotypeString,'animal_id->male_id','round(datediff(now(), dob)/7, 0)->male_age','strain_name->male_strain','genotype_string->male_genotype') *  proj(sln_animal.Animal * sln_animal.GenotypeString,'animal_id->female_id','round(datediff(now(), dob)/7, 0)->female_age','strain_name->female_strain','genotype_string->female_genotype');

        end
    end
end

