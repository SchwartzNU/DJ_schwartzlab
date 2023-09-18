%{
# animal
animal_id                   : int unsigned AUTO_INCREMENT   # unique animal id
---
dob=null                    : date                          # mouse date of birth
sex="Unknown"               : enum('Male','Female','Unknown') # sex of mouse - Male, Female, or Unknown/Unclassified
-> sln_animal.Strain
-> [nullable] sln_animal.Source
%}

classdef Animal < dj.Manual
    methods(Static)

        function animals = living()
            q = sln_animal.Deceased.living();

            animals = q.fetch('animal_id');

            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end
        end

        function animals = tagNumber(animal_ids, liveOnly)

            q = sln_animal.Tag.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sln_animal.Deceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','tag_id');
            animals = rmfield(animals, 'event_id');
            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end
        end

        function animals = assignedProtocol(animal_ids, liveOnly)
            %get the protocol number

            q = sln_animal.AssignProtocol.current * sln_animal.AnimalProtocol;

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sln_animal.Deceased.living();
            end

            if nargin && ~isempty(animal_ids)
                q = restrict_by_animal_ids(q, animal_ids);
            end
            animals = q.fetch('animal_id','protocol_number'); %LIMIT clause not working so...
            animals = rmfield(animals,{'event_id','protocol_name'});
            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end
        end

        function animals = reservedProject(animal_ids)
            %get the protocol number
            q = sln_animal.Animal;
            if nargin && ~isempty(animal_ids)
                q = restrict_by_animal_ids(q, animal_ids);
            end

            a = aggr(q, sln_animal.AnimalEvent * sln_animal.ReservedForProject, ...
                'substring(max(concat(date,entry_time,project_name)), 30)->project_name');
            %animals = q.fetch('animal_id','project_name', 'LIMIT 1 PER animal_id ORDER BY date DESC');
            animals = a.fetch('animal_id','project_name');
            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end

        end

        %
        %         function [result, animals] = isGenotyped(animal_ids)
        %            animals = sl.Animal.genotypeStatus(animal_ids);
        %            result = ismember(animal_ids, [animals.animal_id]);
        %         end

        function animals = withEvent(eventType, animal_ids, liveOnly)
            %has this event

            if nargin>2 && liveOnly
                q = sln_animal.Deceased.living();
            else
                q = sln_animal.Animal();
            end
            q = q * sln_animal.AnimalEvent & feval(sprintf('sln_animal.%s', eventType));

            if nargin>1 && ~isempty(animal_ids)
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id');

            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end

        end

        function [result, animals] = hasEvent(eventType, animal_ids)
            animals = sln_animal.Animal.withEvent(eventType, animal_ids);
            result = ismember(animal_ids, [animals.animal_id]);
        end

        function animals = cageNumber(animal_ids, liveOnly)

            q = sln_animal.AssignCage.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sln_animal.Deceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('*');
            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end
        end

        function full_struct = strainName(animal_ids, liveOnly)
            if nargin>1 && liveOnly
                all_animals = sln_animal.Deceased.living();
            else
                all_animals = sln_animal.Animal;
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                all_animals = restrict_by_animal_ids(all_animals,animal_ids);
            end

            full_struct = proj(all_animals,'strain_name');
        end

        function animals = tagEar(animal_ids, liveOnly)

            q = sln_animal.Tag.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sln_animal.Deceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','tag_ear');
            animals = rmfield(animals, 'event_id');
            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end
        end

        function result = isActiveBreeder(animal_ids)
            q_male = proj(sln_animal.BreedingPair.active_pairs(),'male_id->animal_id');
            q_female = proj(sln_animal.BreedingPair.active_pairs(),'female_id->animal_id');

            if nargin && ~isempty(animal_ids)
                q_male = restrict_by_animal_ids(q_male,animal_ids);
                q_female = restrict_by_animal_ids(q_female,animal_ids);
            end

            animals_male = q_male.fetchn('animal_id');
            animals_female = q_female.fetchn('animal_id');

            result = ismember(animal_ids,animals_male) | ismember(animal_ids,animals_female);
        end

        function animals = earPunch(animal_ids, liveOnly)

            q = sln_animal.Tag.current();

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sln_animal.Deceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','punch');
            animals = rmfield(animals, 'event_id');
            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end
        end

        function animals = roomNumber(animal_ids, liveOnly)

            %q = sln_animal.AssignCage.current * sln_animal.Cage * sln_animal.CageRoom;
            q = sln_animal.AssignCage.current * ...
                proj(sln_animal.CageAssignRoom.current,'*','date->assign_room_date','entry_time->assign_room_entry_time','user_name->assign_room_user_name');

            if nargin>1 && liveOnly
                %restrict by living mice
                q = q & sln_animal.Deceased.living();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','room_number', 'LIMIT 1 PER animal_id');
            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end
        end

        %         function animals = deceasedDate(animal_ids)
        %
        %             %restrict by deceased mice
        %             q = sl.AnimalEventDeceased();
        %
        %             if nargin && ~isempty(animal_ids)
        %                 %restrict by animal_id
        %                 q = restrict_by_animal_ids(q,animal_ids);
        %             end
        %
        %             animals = q.fetch('animal_id','date');
        %             animals = rmfield(animals, 'event_id');
        %             if isempty(animals)
        %                animals = reshape(animals,0,1);
        %             end
        %         end

        function [result, animals] = isCaged(animal_ids)
            animals = sln_animal.Animal.cageNumber(animal_ids);
            result = ismember(animal_ids, [animals.animal_id]);
        end

        function animals = age(animal_ids, liveOnly)
            %returns age as a calendarDuration object

            if nargin>1 && liveOnly
                %restrict by living mice
                q = sln_animal.Deceased.living();
            else
                q = sln_animal.Animal();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals = q.fetch('animal_id','dob');

            ages = num2cell(between(datetime({animals.dob}), date(),'weeks'));
            [animals(:).age] = ages{:};

            % one-liner:
            % [animals(:).ages] = subsref( num2cell(between(datetime({animals.dob}), date())), struct('type','{}', 'subs',':'))

            if isempty(animals)
                animals = reshape(animals,0,1);
            else
                %each animal_id only once
                [~, ind] = unique([animals.animal_id],'first');
                animals = animals(ind);
            end
        end

        %         function animals = genotypeStatus(animal_ids, liveOnly)
        %             %get latest genotype status
        %
        %             q = sl.AnimalEventGenotyped();
        %
        %             if nargin>1 && liveOnly
        %                 q = q & sln_animal.Deceased.living();
        %             end
        %
        %             if nargin && ~isempty(animal_ids)
        %                 %restrict by animal_id
        %                 q = restrict_by_animal_ids(q,animal_ids);
        %             end
        %
        %             animals = q.fetch('animal_id', 'genotype_status', 'LIMIT 1 PER animal_id');
        %
        %             if isempty(animals)
        %                 animals = reshape(animals,0,1);
        %             end
        %         end

        %         function str = genotype_string_for_id(id)
        %             genotype_entries = sln_animal.AnimalEvent * sln_animal.GenotypeResult & sprintf('animal_id = %d',id);
        %             if ~genotype_entries.exists
        %                 str = '?';
        %             else
        %                 str = '';
        %                 loci = unique(fetchn(genotype_entries, 'locus_name'));
        %                 loci_count = length(loci);
        %                 for i=1:loci_count
        %                     cur_alleles = fetch(genotype_entries & sprintf('locus_name = "%s"', loci{i}), '*');
        %                     str = [str, sprintf('%s: %s/%s', cur_alleles(i).locus_name, cur_alleles(i).allele1, cur_alleles(i).allele2)];
        %                     str = strrep(str,'WT', '-');
        %                     if i<loci_count
        %                         str = [str, ', '];
        %                     end
        %                 end
        %             end
        %         end

        function animals = source_info(animal_ids, liveOnly)
            %returns struct of source_id information for each animal

            if nargin>1 && liveOnly
                %restrict by living mice
                q = sln_animal.Deceased.living();
            else
                q = sln_animal.Animal();
            end

            if nargin && ~isempty(animal_ids)
                %restrict by animal_id
                q = restrict_by_animal_ids(q,animal_ids);
            end

            animals_struct = q.fetch('animal_id','source_id');

            if isempty(animals_struct)
                animals = reshape(animals_struct,0,1);
            else
                animals = rmfield(animals_struct,'source_id');
                for i=1:length(animals_struct)
                    id = animals_struct(i).source_id;
                    if id < 90 %Vendor
                        name_str = fetch1(sln_animal.Vendor & sprintf('source_id=%d', id), 'vendor_name');
                    elseif id < 1000 %collaborator
                        name_str = fetch1(sln_animal.Collaborator & sprintf('source_id=%d', id), 'lab_name');
                    else %breeder
                        name_str = 'breeding pair';
                    end

                    animals(i).source_name = sprintf('%d:%s',id,name_str);
                end
            end
        end

    end
end


function q = restrict_by_animal_ids(q, animal_ids)
if ~isa(animal_ids,'cell')
    animal_ids = num2cell(animal_ids);
end
q = q & struct('animal_id', animal_ids);
end


%TODO add back methods from sl.Animal

