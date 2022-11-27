function T = behavior_sessions_N()
all_sessions = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession;
all_sessions_struct = fetch(all_sessions, '*');
purpose_vec = unique({all_sessions_struct.purpose});
animal_type_vec = unique({all_sessions_struct.animal_type_name});
experimenter_vec = unique({all_sessions_struct.user_name});

z = 1;
for p=1:length(purpose_vec)
    for a=1:length(animal_type_vec)
        for e=1:length(experimenter_vec)
            q = all_sessions & ...
                sprintf('user_name="%s"', experimenter_vec{e}) & ...
                sprintf('purpose="%s"', purpose_vec{p}) & ...
                sprintf('animal_type_name="%s"', animal_type_vec{a});
           if q.exists
               S(z).user_name = experimenter_vec{e};
               S(z).purpose = purpose_vec{p};
               S(z).animal_type_name = animal_type_vec{a};
               S(z).N_sessions = q.count;
               S(z).event_ids = fetchn(q,'event_id');
               S(z).animal_ids = unique(fetchn(q,'animal_id'));
               S(z).dates = unique(fetchn(q,'date'));
               z=z+1;
           end
        end
    end
end

T = struct2table(S);