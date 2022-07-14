function [] = updateGenotypeString(animal_ids)
Nids = length(animal_ids);
S = repmat(struct('animal_id', 'genotype'),Nids,1);

for n=1:Nids
    animal_id = animal_ids(n);
    S(n).animal_id = animal_id;

    genotype_result_events = sln_animal.AnimalEvent * sln_animal.GenotypeResult & ...
        sprintf('animal_id=%d', animal_id);

    if ~genotype_result_events.exists
        %no genotype result event
        external_id = fetch1(sln_animal.Animal & sprintf('animal_id=%d',animal_id), 'external_id');
        if contains(external_id, 'OLD_genotype_name')
            str = strrep(external_id, 'OLD_genotype_name', 'amb');
        else
            str = 'WT';
        end
    else
        str = '';
        N = genotype_result_events.count;
        ev_structs = fetch(genotype_result_events,'*');
        for i=1:N
            ev_struct = ev_structs(i);
            if isempty(ev_struct.allele2)
                a2 = '?';
            else
                a2 = ev_struct.allele2;
            end

            str = [str, ev_struct.locus_name, ':' ev_struct.allele1 '/' a2];
            if i<N
                str = [str, ', '];
            end
        end
    end

    S(n).genotype = str;
end

insert(sln_animal.GenotypeString, S, 'REPLACE');