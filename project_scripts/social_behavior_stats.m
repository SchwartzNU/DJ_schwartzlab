%% load data into one big table
sessions = unique(fetchn(sl_behavior.Annotation, 'event_id'));
R_pup = table;
R_sessions = table;
R_cur_session = struct;
for i=1:length(sessions)
    thisSession = sln_animal.SocialBehaviorSession & sprintf('event_id=%d', sessions(i));
    if contains(fetch1(thisSession,'purpose'), 'intruder')
        R = sl_behavior.pup_retrieved_relative_order_for_session(sessions(i));
        R_pup = [R_pup; R];
        %get stimuli
        stims_struct = fetch(sln_animal.SocialBehaviorSessionStimulus & sprintf('event_id=%d', sessions(i)), '*');
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
        [R_cur_session.groom_time, R_cur_session.groom_mean, R_cur_session.groom_frac] = ...
        sl_behavior.duration_for_events_in_session(sessions(i),'groom');
        [R_cur_session.mutualInts] = sl_behavior.count_events_in_session(sessions(i),'mutual interaction');

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
ylim([0 250])
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
ylim([0 250])
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
%% make sub-tables
% pull the conditions in the order I want them plotted
% cannot use strmp or find otherwise it will find "male" conditions inside
% the conditions that are actually "female"
xAxis = zeros(size(R_sessions(1,:)));
for i=1:height(R_sessions)
    if startsWith(R_sessions.purpose(i), 'male_intruder')
        if endsWith(R_sessions.purpose(i), 'smell')
            xAxis(i) = 2;
        else
            xAxis(i) = 1;
        end
    end
    if startsWith(R_sessions.purpose(i), 'female_intruder') 
        if endsWith(R_sessions.purpose(i), 'smell')
            xAxis(i) = 4;
        else 
            xAxis(i) = 3;
        end
    end
    if startsWith(R_sessions.purpose(i), 'novelObj_intruder') 
        if endsWith(R_sessions.purpose(i), 'smell')
            xAxis(i) = 6;
        else
            xAxis(i) = 5;
        end
    end
end
xAxis = xAxis';
xAxis = array2table(xAxis);
R_plots = [R_sessions xAxis];

%% Run a bunch of t tests
male_ttest = R_sessions(R_sessions.purpose=="male_intruder",:);
maleSmell_ttest = R_sessions(R_sessions.purpose=="male_intruder_smell",:);
female_ttest = R_sessions(R_sessions.purpose=="female_intruder",:);
femaleSmell_ttest = R_sessions(R_sessions.purpose=="female_intruder_smell",:);
novelObj_ttest = R_sessions(R_sessions.purpose=="novelObj_intruderControl",:);
novelObjSmell_ttest = R_sessions(R_sessions.purpose=="novelObj_intruderControl_smell",:);

intruder_ttest = [female_ttest; male_ttest];
intruderSmell_ttest = [femaleSmell_ttest; maleSmell_ttest];
% mutual interactions
[fmutints.h,fmutints.p,fmutints.ci,fmutints.stats] = ttest2(female_ttest.mutualInts,femaleSmell_ttest.mutualInts); %p=.04
[mmutints.h,mmutints.p,mmutints.ci,mmutints.stats] = ttest2(male_ttest.mutualInts,maleSmell_ttest.mutualInts);
[intmutints.h,intmutints.p,intmutints.ci,intmutints.stats] = ttest2(intruder_ttest.mutualInts,intruderSmell_ttest.mutualInts);
% window investigation time
[minv_mean.h,minv_mean.p,minv_mean.ci,minv_mean.stats] = ttest2(male_ttest.inv_mean,maleSmell_ttest.inv_mean); 
[mInvTime.h,mInvTime.p,mInvTime.ci,mInvTime.stats] = ttest2(male_ttest.inv_time,maleSmell_ttest.inv_time);
[finv_mean.h,finv_mean.p,finv_mean.ci,finv_mean.stats] = ttest2(female_ttest.inv_mean,femaleSmell_ttest.inv_mean);
[fInvTime.h,fInvTime.p,fInvTime.ci,fInvTime.stats] = ttest2(female_ttest.inv_time,femaleSmell_ttest.inv_time);
[ffracInvTime.h,ffracInvTime.p,ffracInvTime.ci,ffracInvTime.stats] = ttest2(female_ttest.inv_frac,femaleSmell_ttest.inv_frac);
%[mfracInvTime.h,mfracInvTime.p,mfracInvTime.ci,mfracInvTime.stats] = ttest2(male_ttest.inv_frac,maleSmell_ttest.inv_frac);


%[intfracInvTime.h,intfracInvTime.p,intfracInvTime.ci,intfracInvTime.stats] = ttest2(intruder_ttest.inv_frac,intruderSmell_ttest.inv_frac);

%% Make figures
figure()
subplot(1,3,1)
xTotal = xAxis;
scatter(xTotal.xAxis, R_plots.inv_time);
formatSpec = 'p = %.4f';
pmascTotalInvTime = mInvTime.p;
pfInvTime = fInvTime.p;
str = sprintf(formatSpec,pmascTotalInvTime);
h=text(1.5,150,str);
set(h,'Rotation',90);
y=195;
line([1,2],[y,y],'Color','black', 'Marker', '|')
line([3,4],[y,y],'Color','black', 'Marker', '|')
str = sprintf(formatSpec,pfInvTime);
h=text(3.5,150,str);
set(h,'Rotation',90);
title('Total investigation')
ylabel('Time (s)');
xticks([1 2 3 4 5 6])
xlim([-0.5 6.5])
ylim([0 200])
labels = {'Male intruder', 'Smelly Male', 'Female intruder', ...
    'Smelly Female', 'Novel object', 'Smelly Object'};
xticklabels(labels)
%igor part
plotStruct = struct;
plotStruct.xvals = xTotal.xAxis;
plotStruct.yvals = R_plots.inv_time;
plotStruct.pmascTotalInvTime = pmascTotalInvTime;
plotStruct.pfInvTime = pfInvTime;
plotStruct.labels = labels;
% exportStructToHDF5(plotStruct,'PupRet_totalWindowInvestigationTime.h5', '/');
subplot(1,3,2)
xTotal = xAxis;
scatter(xTotal.xAxis, R_plots.inv_mean);
pmascMeanInvTime = minv_mean.p;
pfemMeanInvTime = finv_mean.p;
str = sprintf(formatSpec,pmascMeanInvTime);
h=text(1.5,15,str);
set(h,'Rotation',90);
y=19.5;
line([1,2],[y,y],'Color','black', 'Marker', '|')
str = sprintf(formatSpec,pfemMeanInvTime);
h=text(3.5,15,str);
set(h,'Rotation',90);
line([3,4],[y,y],'Color','black', 'Marker', '|')
title('Mean investigation')
ylabel('Time (s)');
xticks([1 2 3 4 5 6])
xlim([-0.5 6.5])
ylim([0 20])
xticklabels({'Male intruder', 'Smelly Male', 'Female intruder', ...
    'Smelly Female', 'Novel object', 'Smelly Object'})
%igor part
plotStruct = struct;
plotStruct.xvals = xTotal.xAxis;
plotStruct.yvals = R_plots.inv_mean;
plotStruct.pmascMeanInvTime = pmascMeanInvTime;
plotStruct.pfemMeanInvTime = pfemMeanInvTime;
plotStruct.labels = labels;
% exportStructToHDF5(plotStruct,'PupRet_meanWindowInvestigationTime.h5', '/');
subplot(1,3,3)
figure
xTotal = xAxis;
scatter(xTotal.xAxis, R_plots.inv_frac);
% pmascMeanInvTime = minv_mean.p;
formatSpec = 'p = %.4f';
pfemFractInvTime = ffracInvTime.p;
str = sprintf(formatSpec,pfemFractInvTime);
h=text(3.5,0.38,str);
set(h,'Rotation',90);
y=.49;
line([1,2],[y,y],'Color','black', 'Marker', '|')
% str = sprintf(formatSpec,finv_fract);
% h=text(3.5,15,str);
% set(h,'Rotation',90);
line([3,4],[y,y],'Color','black', 'Marker', '|')
title('Fraction investigation')
ylabel('Time (s)');
xticks([1 2 3 4 5 6])
xlim([-0.5 6.5])
ylim([0 0.5])
xticklabels({'Male intruder', 'Smelly Male', 'Female intruder', ...
    'Smelly Female', 'Novel object', 'Smelly Object'})
sgtitle('Maternal Window Investigation Time w/ Intruders')
%igor part
plotStruct = struct;
plotStruct.xvals = xTotal.xAxis;
plotStruct.yvals = R_plots.inv_frac;
%plotStruct.pmascMeanInvTime = pmascMeanInvTime;
plotStruct.pfemFractInvTime = pfemFractInvTime;
plotStruct.labels = labels;
% exportStructToHDF5(plotStruct,'PupRet_fractionWindowInvestigationTime.h5', '/');

%% groom time
figure()
subplot(1,3,1)
xTotal = xAxis;
scatter(xTotal.xAxis, R_plots.groom_time);
title('Total groom')
ylabel('Time (s)');
xticks([1 2 3 4 5 6])
xlim([-0.5 6.5])
ylim([0 100])
xticklabels({'Male intruder', 'Smelly Male', 'Female intruder', ...
    'Smelly Female', 'Novel object', 'Smelly Object'})
subplot(1,3,2)
xTotal = xAxis;
scatter(xTotal.xAxis, R_plots.groom_mean);
title('Mean groom')
ylabel('Time (s)');
xticks([1 2 3 4 5 6])
xlim([-0.5 6.5])
ylim([0 10])
xticklabels({'Male intruder', 'Smelly Male', 'Female intruder', ...
    'Smelly Female', 'Novel object', 'Smelly Object'})
subplot(1,3,3)
xTotal = xAxis;
scatter(xTotal.xAxis, R_plots.groom_frac);
title('Fraction groom')
ylabel('Time (s)');
xticks([1 2 3 4 5 6])
xlim([-0.5 6.5])
ylim([0 .33])
xticklabels({'Male intruder', 'Smelly Male', 'Female intruder', ...
    'Smelly Female', 'Novel object', 'Smelly Object'})
sgtitle('Maternal Groom Time w/ Intruders')
%% mutual interactions
figure()
xTotal = xAxis;
scatter(xTotal.xAxis, R_plots.mutualInts, 'black');
formatSpec = 'p = %.4f';
pfemMutuals = fmutints.p;
pmascMutuals = mmutints.p;
pintruderMutuals = intmutints.p;
str = sprintf(formatSpec,pfemMutuals);
text(3.15,50,str)
str = sprintf(formatSpec,pmascMutuals);
text(1.15,50,str)
str = sprintf(formatSpec,pintruderMutuals);
text(2.15,50,str)
ylabel('Count');
xticks([1 2 3 4 5 6])
xlim([0.5 4.5])
y = 48;
line([1,2],[y,y],'Color','black', 'Marker', '|')
line([3,4],[y,y],'Color','black', 'Marker', '|')
labels = {'Male intruder', 'Smelly Male', 'Female intruder', ...
    'Smelly Female', 'Novel object', 'Smelly Object'};
xticklabels(labels)
sgtitle('Total mutual interaction events')
%igor part
plotStruct = struct;
plotStruct.xvals = xTotal.xAxis;
plotStruct.yvals = R_plots.mutualInts;
plotStruct.pmascMutuals = pmascMutuals;
plotStruct.pfemMutuals = pfemMutuals;
plotStruct.labels = labels;
% exportStructToHDF5(plotStruct,'PupRet_Mutual_interaction_events.h5', '/');
