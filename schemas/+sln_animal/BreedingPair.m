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
        function q = active()
            
            %TODO: refactor...
            
            %% Current paired breeders
            %get the breeding pairs, promote male and female ids to primary
            q1 = proj(sln_animal.Animal,'animal_id->male_id') * proj(sln_animal.Animal,'animal_id->female_id') * sln_animal.BreedingPair;
            
            %get the current cage numbers
            q1 = q1 * proj(sln_animal.AssignCage.current,'animal_id->female_id','event_id->female_event','cage_number->female_cage') * proj(sln_animal.AssignCage.current,'animal_id->male_id','event_id->male_event','cage_number->male_cage');
            
            %get only the pairs where the current cage is the same
            q1 = proj(q1, 'female_cage=male_cage -> same_cage') & 'same_cage = 1';
            
            %keep only the pairs where both mice are alive
            q1 = q1 - (proj(sln_animal.AnimalEvent * sln_animal.Deceased,'animal_id->female_id','event_id->female_deceased') | proj(sln_animal.AnimalEvent * sln_animal.Deceased,'animal_id->male_id','event_id->male_deceased'));
            
            %% Unpaired females still in a breeding cage
            
            
            %% Unpaired animals reserved for breeding
            
            %% 
            % return only the expected columns
            q = sln_animal.BreedingPair & q1;
            
        end

        function ids = active_animal_ids(sex)
            if nargin < 1
                sex = 'both';
            end
            q = sln_animal.BreedingPair.active();
            if ~q.exists
                ids = [];
                return;
            end
            male_ids = fetchn(q,'male_id');
            female_ids = fetchn(q,'female_id');
            if strcmp(sex,'male')
                ids = male_ids;
            elseif strcmp(sex,'female')
                ids = female_ids;
            else
                ids = [male_ids; female_ids];
            end
        end
        
        function D = breeders_table()
            
            % ever paired
            %cage = sln_animal.BreedingPair * sln_animal.Cage * proj(sln_animal.Animal & 'sex="Female"', 'animal_id->female_id') * proj(sln_animal.AssignCage.current,'animal_id->female_id','event_id->female_event','cage_number')  * proj(sln_animal.Animal & 'sex="Male"', 'animal_id->male_id') * proj(sln_animal.AssignCage.current,'animal_id->male_id','event_id->male_event','cage_number');
            cage = sln_animal.Cage * proj(sln_animal.AnimalEvent * sln_animal.AssignCage, 'lead(date) over(partition by animal_id order by date)->end_date', 'date->start_date','animal_id','cage_number') * proj(sln_animal.Animal,'sex');
            cage = aggr(sln_animal.BreedingPair, proj(cage & 'sex="Female"', 'animal_id->female_id','event_id->female_event','start_date->female_date') * proj(cage & 'sex="Male"', 'animal_id->male_id','event_id->male_event','start_date->male_date'), '*', 'convert(substring(max(concat(female_date, cage_number)), 11), unsigned)->cage_number','if(max(female_date)>max(male_date),max(female_date),max(male_date))->pair_date');
            % TODO: this doesn't actually check to see that they were in
            % the cage at the same time... need to restrict by: '(male_start < female_end OR female_end is null) AND (female_start < male_end OR male_end is null)';
            
            % remove cages where both the male and female are currently retired
            male = (sln_animal.Animal & 'sex="Male"') & (sln_animal.AnimalEvent * (sln_animal.ReservedForProject & 'project_name="Breeding" OR project_name="Former breeder"'));
            male_ev = (sln_animal.Animal & 'sex="Male"') * sln_animal.AnimalEvent * (sln_animal.ReservedForProject & 'project_name="Breeding" OR project_name="Former breeder"');
            male_status = aggr(male, male_ev, 'substring(max(concat(date, entry_time, project_name)), 30)->project_name', 'animal_id->male_id'); %"scalar-aggregate reduction"
             
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
            r = proj(sln_animal.BreedingPair,'strain_name','male_id','female_id') * aggr(sln_animal.BreedingPair, cc, 'any_value(cage_number) -> cage_number', 'any_value(pair_date) -> pair_date', 'any_value(litter_count)->litter_count', 'any_value(litter_dates)->litter_dates', 'any_value(wean_counts)->wean_counts', 'any_value(next_wean)->next_wean') * rn;
            
                        
            r = r - proj(cage & proj(male_status & 'project_name="Former breeder"') & proj(female_status & 'project_name="Former breeder"'));
            
            %remove cages where the female is deceased
            deceased = sln_animal.Animal * sln_animal.AnimalEvent * sln_animal.Deceased;
            r = r - proj(deceased,'animal_id->female_id');
            
            %remove cages where the female is retired and the male is deceased
            r = r - proj(cage & proj(deceased,'animal_id->male_id') & proj(female_status & 'project_name="Former breeder"'));
            
            % if the female is retired and has had a birth without a wean,
            % we will keep her too
            
            
            
            
            % add ages, strains, genotypes
            D = r * proj(sln_animal.Animal * sln_animal.GenotypeString,'animal_id->male_id','round(datediff(now(), dob)/7, 0)->male_age','strain_name->male_strain','genotype_string->male_genotype') *  proj(sln_animal.Animal * sln_animal.GenotypeString,'animal_id->female_id','round(datediff(now(), dob)/7, 0)->female_age','strain_name->female_strain','genotype_string->female_genotype');

        end
    end
end

