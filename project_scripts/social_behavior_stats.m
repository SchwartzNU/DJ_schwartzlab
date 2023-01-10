%% load data into one big table

sessions = unique(fetchn(sl_behavior.Annotation, 'event_id')); %for now this works because all the sessions in there are Devon's pup retrieval
R_pup = table;
for i=1:length(sessions)
    %disp(i); disp(sessions(i)); pause; 
    R = sl_behavior.pup_retrieved_relative_order_for_session(sessions(i));
    R_pup = [R_pup; R];
end

%% make sub-tables
R_no_smell = R_pup(strcmp(R_pup.Smell_present,"F"), :);
R_smell = R_pup(strcmp(R_pup.Smell_present,"T"), :);

R_male_smell = R_smell(strcmp(R_smell.Intruder_type,"Male"), :);
R_male_nosmell = R_no_smell(strcmp(R_no_smell.Intruder_type,"Male"), :);

R_female_smell = R_smell(strcmp(R_smell.Intruder_type,"Female"), :);
R_female_nosmell = R_no_smell(strcmp(R_no_smell.Intruder_type,"Female"), :);

R_object_smell = R_smell(strcmp(R_smell.Intruder_type,"object"), :);
R_object_nosmell = R_no_smell(strcmp(R_no_smell.Intruder_type,"object"), :);


%% get the data means
intruder_distances = ["0", "60", "120", "180"];
N = length(intruder_distances);

order_male_smell_mean = zeros(N,1);
order_male_smell_sem = zeros(N,1);

order_female_smell_mean = zeros(N,1);
order_female_smell_sem = zeros(N,1);

order_male_nosmell_mean = zeros(N,1);
order_male_nosmell_sem = zeros(N,1);

order_female_nosmell_mean = zeros(N,1);
order_female_nosmell_sem = zeros(N,1);

order_object_smell_mean = zeros(N,1);
order_object_smell_sem = zeros(N,1);

order_object_nosmell_mean = zeros(N,1);
order_object_nosmell_sem = zeros(N,1);

latency_male_smell_mean = zeros(N,1);
latency_male_smell_sem = zeros(N,1);

latency_female_smell_mean = zeros(N,1);
latency_female_smell_sem = zeros(N,1);

latency_male_nosmell_mean = zeros(N,1);
latency_male_nosmell_sem = zeros(N,1);

latency_female_nosmell_mean = zeros(N,1);
latency_female_nosmell_sem = zeros(N,1);

latency_object_smell_mean = zeros(N,1);
latency_object_smell_sem = zeros(N,1);

latency_object_nosmell_mean = zeros(N,1);
latency_object_nosmell_sem = zeros(N,1);

for i=1:N
    order_male_smell = R_male_smell.Pup_order(strcmp(R_male_smell.Pup_degrees_from_intruder, intruder_distances(i)));
    order_female_smell = R_female_smell.Pup_order(strcmp(R_female_smell.Pup_degrees_from_intruder, intruder_distances(i)));
    order_object_smell = R_object_smell.Pup_order(strcmp(R_object_smell.Pup_degrees_from_intruder, intruder_distances(i)));
    
    order_male_smell_mean(i) = mean(order_male_smell);
    order_male_smell_sem(i) = std(order_male_smell) ./ sqrt(length(order_male_smell) - 1);
    order_female_smell_mean(i) = mean(order_female_smell);
    order_female_smell_sem(i) = std(order_female_smell) ./ sqrt(length(order_female_smell) - 1);
    order_object_smell_mean(i) = mean(order_object_smell);
    order_object_smell_sem(i) = std(order_object_smell) ./ sqrt(length(order_object_smell) - 1);

    order_male_nosmell = R_male_nosmell.Pup_order(strcmp(R_male_nosmell.Pup_degrees_from_intruder, intruder_distances(i)));
    order_female_nosmell = R_female_nosmell.Pup_order(strcmp(R_female_nosmell.Pup_degrees_from_intruder, intruder_distances(i)));
    order_object_nosmell = R_object_nosmell.Pup_order(strcmp(R_object_nosmell.Pup_degrees_from_intruder, intruder_distances(i)));
    
    order_male_nosmell_mean(i) = mean(order_male_nosmell);
    order_male_nosmell_sem(i) = std(order_male_nosmell) ./ sqrt(length(order_male_nosmell) - 1);
    order_female_nosmell_mean(i) = mean(order_female_nosmell);
    order_female_nosmell_sem(i) = std(order_female_nosmell) ./ sqrt(length(order_female_nosmell) - 1);
    order_object_nosmell_mean(i) = mean(order_object_nosmell);
    order_object_nosmell_sem(i) = std(order_object_nosmell) ./ sqrt(length(order_object_nosmell) - 1);

    latency_male_smell = R_male_smell.Pup_retrieval_latency(strcmp(R_male_smell.Pup_degrees_from_intruder, intruder_distances(i)));
    latency_female_smell = R_female_smell.Pup_retrieval_latency(strcmp(R_female_smell.Pup_degrees_from_intruder, intruder_distances(i)));
    latency_object_smell = R_object_smell.Pup_retrieval_latency(strcmp(R_object_smell.Pup_degrees_from_intruder, intruder_distances(i)));
    
    latency_male_smell_mean(i) = mean(latency_male_smell);
    latency_male_smell_sem(i) = std(latency_male_smell) ./ sqrt(length(latency_male_smell) - 1);
    latency_female_smell_mean(i) = mean(latency_female_smell);
    latency_female_smell_sem(i) = std(latency_female_smell) ./ sqrt(length(latency_female_smell) - 1);
    latency_object_smell_mean(i) = mean(latency_object_smell);
    latency_object_smell_sem(i) = std(latency_object_smell) ./ sqrt(length(latency_object_smell) - 1);

    latency_male_nosmell = R_male_nosmell.Pup_retrieval_latency(strcmp(R_male_nosmell.Pup_degrees_from_intruder, intruder_distances(i)));
    latency_female_nosmell = R_female_nosmell.Pup_retrieval_latency(strcmp(R_female_nosmell.Pup_degrees_from_intruder, intruder_distances(i)));
    latency_object_nosmell = R_object_nosmell.Pup_retrieval_latency(strcmp(R_object_nosmell.Pup_degrees_from_intruder, intruder_distances(i)));
    
    latency_male_nosmell_mean(i) = mean(latency_male_nosmell);
    latency_male_nosmell_sem(i) = std(latency_male_nosmell) ./ sqrt(length(latency_male_nosmell) - 1);
    latency_female_nosmell_mean(i) = mean(latency_female_nosmell);
    latency_female_nosmell_sem(i) = std(latency_female_nosmell) ./ sqrt(length(latency_female_nosmell) - 1);
    latency_object_nosmell_mean(i) = mean(latency_object_nosmell);
    latency_object_nosmell_sem(i) = std(latency_object_nosmell) ./ sqrt(length(latency_object_nosmell) - 1);
    
end

%% plots
intruder_distances = categorical(str2double(intruder_distances));

figure;
subplot(3,1,1);
errorbar(intruder_distances, order_male_smell_mean, order_male_smell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval order');
title('Male intruder with smell')

subplot(3,1,2);
errorbar(intruder_distances, order_female_smell_mean, order_female_smell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval order');
title('Female intruder with smell')

subplot(3,1,3);
errorbar(intruder_distances, order_object_smell_mean, order_object_smell_sem);
xlabel('Degrees from object')
ylabel('Pup retrieval order');
title('Object with smell')

figure;
subplot(3,1,1);
errorbar(intruder_distances, order_male_nosmell_mean, order_male_nosmell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval order');
title('Male intruder no smell')

subplot(3,1,2);
errorbar(intruder_distances, order_female_nosmell_mean, order_female_nosmell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval order');
title('Female intruder no smell')

subplot(3,1,3);
errorbar(intruder_distances, order_object_nosmell_mean, order_object_nosmell_sem);
xlabel('Degrees from object')
ylabel('Pup retrieval order');
title('Object no smell')

figure;
subplot(3,1,1);
errorbar(intruder_distances, latency_male_smell_mean, latency_male_smell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval latency (s)');
title('Male intruder with smell')

subplot(3,1,2);
errorbar(intruder_distances, latency_female_smell_mean, latency_female_smell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval latency (s)');
title('Female intruder with smell')

subplot(3,1,3);
errorbar(intruder_distances, latency_object_smell_mean, latency_object_smell_sem);
xlabel('Degrees from object')
ylabel('Pup retrieval latency (s)');
title('Object with smell')

figure;
subplot(3,1,1);
errorbar(intruder_distances, latency_male_nosmell_mean, latency_male_nosmell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval latency (s)');
title('Male intruder no smell')

subplot(3,1,2);
errorbar(intruder_distances, latency_female_nosmell_mean, latency_female_nosmell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval latency (s)');
title('Female intruder no smell')

subplot(3,1,3);
errorbar(intruder_distances, latency_object_nosmell_mean, latency_object_nosmell_sem);
xlabel('Degrees from object')
ylabel('Pup retrieval latency (s)');
title('Object no smell')


%% fit some linear mixed-effects models
model_formula_order = 'Pup_order~Pup_degrees_from_intruder+(1|Animal_id)+(Pup_degrees_from_intruder-1|Animal_id)';
model_formula_latency = 'Pup_retrieval_latency~Pup_degrees_from_intruder+(1|Animal_id)+(Pup_degrees_from_intruder-1|Animal_id)';

lme_order_male_smell = fitlme(R_male_smell,model_formula_order);
lme_order_male_nosmell = fitlme(R_male_nosmell,model_formula_order);
lme_order_female_smell = fitlme(R_female_smell,model_formula_order);
lme_order_female_nosmell = fitlme(R_female_nosmell,model_formula_order);

lme_latency_male_smell = fitlme(R_male_smell,model_formula_latency);
lme_latency_male_nosmell = fitlme(R_male_nosmell,model_formula_latency);
lme_latency_female_smell = fitlme(R_female_smell,model_formula_latency);
lme_latency_female_nosmell = fitlme(R_female_nosmell,model_formula_latency);


