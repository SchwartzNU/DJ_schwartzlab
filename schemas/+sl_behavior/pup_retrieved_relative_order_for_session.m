function result_table = pup_retrieved_relative_order_for_session(event_id)
intruder = sln_animal.SocialBehaviorSessionStimulus * sln_animal.AnimalEvent & ...
    sprintf('event_id=%d',event_id) & 'stim_type="intruder"';

test_animal = fetch1(sln_animal.SocialBehaviorSession * sln_animal.AnimalEvent & ...
    sprintf('event_id=%d',event_id), 'animal_id');

if intruder.exists
    intruder_window = fetch1(intruder, 'arm');
    intruder_id = fetch1(intruder, 'stimulus_animal_id');
    intruder_type = fetch1(sln_animal.Animal & ...
        sprintf('animal_id=%d', intruder_id), 'sex');
else
    object = sln_animal.SocialBehaviorSessionStimulus * sln_animal.AnimalEvent & ...
        sprintf('event_id=%d',event_id) & 'stim_type="novel object"';
    intruder_type = 'object';
    intruder_window = fetch1(object, 'arm');
end

purpose = fetch1(sln_animal.SocialBehaviorSession * sln_animal.AnimalEvent & ...
    sprintf('event_id=%d',event_id), 'purpose');

if contains(purpose, 'smell')
    smell_condition = 'T';
else
    smell_condition = 'F';
end

n_pups = 6;

n_locations = 6;
fps = 15;

pup_order = fetchn(sl_behavior.Annotation & ...
    sprintf('event_id=%d',event_id) & ...
    'annotation_name="retrieve pup"' & 'LIMIT 100 PER duration ORDER BY frame ASC','modifier');

door_open_frame = fetchn(sl_behavior.Annotation & ...
    sprintf('event_id=%d',event_id) & ...
    'annotation_name="door open"','frame');

door_open_frame = door_open_frame(1);

pup_frame = fetchn(sl_behavior.Annotation & ...
    sprintf('event_id=%d',event_id) & ...
    'annotation_name="retrieve pup"' & 'LIMIT 100 PER duration ORDER BY frame ASC','frame');

pup_time = double((pup_frame - door_open_frame) / fps);

n_retrievals = length(pup_order);

distance_from_intruder = zeros(n_retrievals,1);

for i=1:n_retrievals
    pup_number = str2double(pup_order{i}(4:end));
    switch intruder_window
        case 'A'
            if pup_number == 1
                distance_from_intruder(i) = 0;
            elseif pup_number == 2 || pup_number == 6
                distance_from_intruder(i) = 60;
            elseif pup_number == 3 || pup_number == 5
                distance_from_intruder(i) = 120;
            else
                distance_from_intruder(i) = 180;
            end

        case 'B'
            if pup_number == 3
                distance_from_intruder(i) = 0;
            elseif pup_number == 2 || pup_number == 4
                distance_from_intruder(i) = 60;
            elseif pup_number == 1 || pup_number == 5
                distance_from_intruder(i) = 120;
            else
                distance_from_intruder(i) = 180;
            end

        case 'C'
            if pup_number == 5
                distance_from_intruder(i) = 0;
            elseif pup_number == 4 || pup_number == 6
                distance_from_intruder(i) = 60;
            elseif pup_number == 1 || pup_number == 3
                distance_from_intruder(i) = 120;
            else
                distance_from_intruder(i) = 180;
            end
    end
end

result_table = table('Size', [n_retrievals,  6], 'VariableNames', ...
    {'Intruder_type', ...
    'Smell_present', ...
    'Animal_id', ...
    'Pup_order',...
    'Pup_degrees_from_intruder', ...
    'Pup_retrieval_latency'...
    }, ...
    'VariableTypes', ...
    {'string', ...
    'string', ...
    'string', ...
    'double', ...
    'string', ...
    'double'...
    });

result_table.Pup_order = [1:n_retrievals]';
result_table.Pup_degrees_from_intruder = string(distance_from_intruder);
result_table.Smell_present = repmat(smell_condition, n_retrievals, 1);
result_table.Intruder_type = repmat(string(intruder_type), n_retrievals, 1);
result_table.Pup_retrieval_latency = pup_time;
result_table.Animal_id = num2str(repmat(test_animal, n_retrievals, 1));

