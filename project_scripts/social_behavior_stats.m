%% load data into one big table

sessions = unique(fetchn(sl_behavior.Annotation, 'event_id')); %for now this works because all the sessions in there are Devon's pup retrieval

R_pup = table;
R_sessions = table;
R_cur_session = struct;

for i=1:length(sessions)    
    %disp(i); disp(sessions(i)); pause; 
    thisSession = sln_animal.SocialBehaviorSession & sprintf('event_id=%d', sessions(i));
    if contains(fetch1(thisSession,'purpose'), 'intruder')
        R = sl_behavior.pup_retrieved_relative_order_for_session(sessions(i));        
        R_pup = [R_pup; R];

        %get stimuli
        stims_struct = fetch(sln_animal.SocialBehaviorSessionStimulus & sprintf('event_id=%d', sessions(i)), '*');
        %pause; 
        R_cur_session.purpose = string(fetch1(thisSession,'purpose'));
        for j=1:length(stims_struct)
            if ~strcmp(stims_struct(j).stim_type,'empty')
                R_cur_session.stim_type = string(stims_struct(j).stim_type);                    
                intruder_arm = stims_struct(j).arm;
            end
        end        
        sessions(i)
        [R_cur_session.inv_time, R_cur_session.inv_mean, R_cur_session.inv_frac] = ...
            sl_behavior.duration_for_events_in_session(sessions(i),'investigate window',['window' intruder_arm]);         
        R_sessions = [R_sessions; struct2table(R_cur_session)];
    end    
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
ylim([0 10])

subplot(3,1,2);
errorbar(intruder_distances, order_female_smell_mean, order_female_smell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval order');
title('Female intruder with smell')
ylim([0 10])

subplot(3,1,3);
errorbar(intruder_distances, order_object_smell_mean, order_object_smell_sem);
xlabel('Degrees from object')
ylabel('Pup retrieval order');
title('Object with smell')
ylim([0 10])

figure;
subplot(3,1,1);
errorbar(intruder_distances, order_male_nosmell_mean, order_male_nosmell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval order');
title('Male intruder no smell')
ylim([0 10])

subplot(3,1,2);
errorbar(intruder_distances, order_female_nosmell_mean, order_female_nosmell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval order');
title('Female intruder no smell')
ylim([0 10])

subplot(3,1,3);
errorbar(intruder_distances, order_object_nosmell_mean, order_object_nosmell_sem);
xlabel('Degrees from object')
ylabel('Pup retrieval order');
title('Object no smell')
ylim([0 10])

figure;
subplot(3,1,1);
errorbar(intruder_distances, latency_male_smell_mean, latency_male_smell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval latency (s)');
title('Male intruder with smell')
ylim([0 200])
subplot(3,1,2);
errorbar(intruder_distances, latency_female_smell_mean, latency_female_smell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval latency (s)');
title('Female intruder with smell')
ylim([0 200])
subplot(3,1,3);
errorbar(intruder_distances, latency_object_smell_mean, latency_object_smell_sem);
xlabel('Degrees from object')
ylabel('Pup retrieval latency (s)');
title('Object with smell')
ylim([0 200])

figure;
subplot(3,1,1);
errorbar(intruder_distances, latency_male_nosmell_mean, latency_male_nosmell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval latency (s)');
title('Male intruder no smell')
ylim([0 200])

subplot(3,1,2);
errorbar(intruder_distances, latency_female_nosmell_mean, latency_female_nosmell_sem);
xlabel('Degrees from intruder')
ylabel('Pup retrieval latency (s)');
title('Female intruder no smell')
ylim([0 200])

subplot(3,1,3);
errorbar(intruder_distances, latency_object_nosmell_mean, latency_object_nosmell_sem);
xlabel('Degrees from object')
ylabel('Pup retrieval latency (s)');
title('Object no smell')
ylim([0 200])

%% fit some linear mixed-effects models
model_formula_order = 'Pup_order~Pup_degrees_from_intruder+(1|Animal_id)+(Pup_degrees_from_intruder-1|Animal_id)';
model_formula_latency = 'Pup_retrieval_latency~Pup_degrees_from_intruder+(1|Animal_id)+(Pup_degrees_from_intruder-1|Animal_id)';

lme_order_male_smell = fitlme(R_male_smell,model_formula_order);
lme_order_male_nosmell = fitlme(R_male_nosmell,model_formula_order);
lme_order_female_smell = fitlme(R_female_smell,model_formula_order);
lme_order_female_nosmell = fitlme(R_female_nosmell,model_formula_order);
lme_order_object_smell = fitlme(R_object_smell,model_formula_order);
lme_order_object_nosmell = fitlme(R_object_nosmell,model_formula_order);

lme_latency_male_smell = fitlme(R_male_smell,model_formula_latency);
lme_latency_male_nosmell = fitlme(R_male_nosmell,model_formula_latency);
lme_latency_female_smell = fitlme(R_female_smell,model_formula_latency);
lme_latency_female_nosmell = fitlme(R_female_nosmell,model_formula_latency);
lme_latency_object_smell = fitlme(R_object_smell,model_formula_latency);
lme_latency_object_nosmell = fitlme(R_object_nosmell,model_formula_latency);

