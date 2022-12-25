%% load the datagroup with the SMS data
load DataGroups/SMS_NF1.mat;

%% Display the group statistics for the dataset
animals = sln_animal.Animal * sln_animal.GenotypeString & proj(data_group,'source_id->cell_source');
males = animals & 'sex="Male"';
females = animals & 'sex="Female"';

het = animals & 'genotype_string="NF1(NF1-KO/WT)"';
WT = animals & 'genotype_string="NF1(WT/WT)"';

fprintf("-----------\n");
fprintf("%d total animals\n", animals.count);
fprintf("%d male; %d female\n", males.count, females.count);
fprintf("%d NF1 het; %d NF1 WT\n", het.count, WT.count);

cells = sln_cell.Cell * proj(sln_cell.RetinaQuadrant,'image_id->quad_image_id','*') * sln_cell.AssignType.current & proj(data_group,'image_id->not_used');
all_types = unique(fetchn(cells, 'cell_type'));

fprintf("-----------\n");
fprintf("%d total cells\n", cells.count);
for i=1:length(all_types)
    thisType = cells & sprintf('cell_type="%s"', all_types{i});
    fprintf('%s: %d\n', all_types{i}, thisType.count);
end

%% set up table to hold results
q = sln_results.DatasetSMSCA & proj(data_group);
R = sln_results.toMatlabTable(q);
N = height(R);

T = table('Size',[N,18],'VariableTypes',...
    {'string',...
    'string',...
    'string',...
    'string',...
    'string',...
    'string',...
    'double',...
    'double',...
    'double',...
    'double',...
    'double',...
    'double',...
    'double',...
    'double',...
    'double',...
    'double',...
    'double',...
    'double'...
    },...
    'VariableNames',...
    {'genotype', ...
    'sex',...
    'which_eye', ...
    'quadrant', ...
    'cell_type', ...
    'animal_id',...
    'peak_FR', ...
    'baseline_FR', ...
    'min_spikes_ON', ...
    'min_spikes_OFF', ...
    'min_size_ON', ...
    'min_size_OFF', ...
    'peak_size_ON', ...
    'peak_size_OFF', ...
    'peak_spikes_ON', ...
    'peak_spikes_OFF', ...
    'half_peak_size', ...
    'SI'...
    });


%% get SMS results data for all of them
for i=1:N
    fprintf('Collecting data for cell %d of %d\n', i, N);
    thisCell = fetch(cells & ...
        sprintf('file_name="%s"', R.file_name{i}) & ...
        sprintf('source_id="%d"', R.source_id(i)), '*');
    thisAnimal = fetch(animals & sprintf('animal_id=%d',thisCell.animal_id), '*');
    T.genotype(i) = thisAnimal.genotype_string;
    T.sex(i) = thisAnimal.sex;
    T.animal_id(i) = sprintf('DJID_%d', thisAnimal.animal_id);
    T.which_eye(i) = thisCell.side;
    T.quadrant(i) = thisCell.quadrant;
    T.cell_type(i) = thisCell.cell_type;
    
    %Fit DOG model to data
%     yvals = R.spikes_stim_mean{i} - R.baseline_rate_hz(i); %subtract baseline rate
%     xvals = R.spot_sizes{i};
% 
%     if strcmp(thisCell.cell_type, 'ON alpha')
%         init_params = [max(yvals), 100, max(yvals)/2, 400];
%     else
%         init_params = [min(yvals), 100, min(yvals)/2, 400];
%     end
% 
%     fit_params = nlinfit(xvals,yvals,@diffCumGauss,init_params);
%     y_fit = diffCumGauss(fit_params,xvals);
%     figure(1);
%     scatter(xvals,yvals,'kx');
%     hold('on');
%     plot(xvals,y_fit,'r');
%     hold('off');
%     pause;    

    T.peak_FR(i) = max(R.sms_psth{i}(:));
    [T.peak_spikes_ON(i), ind_ON_max] = max(R.spikes_stim_mean{i});
    T.peak_size_ON(i) = R.spot_sizes{i}(ind_ON_max);
    [T.peak_spikes_OFF(i), ind] = max(R.spikes_tail_mean{i});
    T.peak_size_OFF(i) = R.spot_sizes{i}(ind);
    [T.min_spikes_ON(i), ind_ON_min] = min(R.spikes_stim_mean{i});
    T.min_size_ON(i) = R.spot_sizes{i}(ind_ON_min);
    [T.min_spikes_OFF(i), ind] = min(R.spikes_tail_mean{i});
    T.min_size_OFF(i) = R.spot_sizes{i}(ind);
    T.baseline_FR(i) = R.baseline_rate_hz(i);
    if strcmp(thisCell.cell_type, 'ON alpha')
        spikes_ON_large = R.spikes_stim_mean{i}(end);
        T.SI(i) = (T.peak_spikes_ON(i) - spikes_ON_large) / (T.peak_spikes_ON(i) + spikes_ON_large);

        xvals = R.spikes_stim_mean{i}(1:ind_ON_max);
        yvals = R.spot_sizes{i}(1:ind_ON_max);
        [xvals_sorted, ind] = sort(xvals,'ascend');
        yvals_sorted = yvals(ind);
        [xvals_sorted, ind] = unique(xvals_sorted);
        yvals_sorted = yvals_sorted(ind);
        try
            F = griddedInterpolant(xvals_sorted,yvals_sorted);
            T.half_peak_size(i) = F(T.peak_spikes_ON(i)/2);
        catch
            T.half_peak_size(i) = nan;
        end
%         T.half_peak_size(i) = interp1(R.spikes_stim_mean{i}(1:ind_ON_max),R.spot_sizes{i}(1:ind_ON_max),...
%             T.peak_spikes_ON(i)/2,"linear");
    else
        T.SI(i) = nan;

        xvals = R.spikes_stim_mean{i}(1:ind_ON_min);
        yvals = R.spot_sizes{i}(1:ind_ON_min);
        [xvals_sorted, ind] = sort(xvals,'ascend');
        yvals_sorted = yvals(ind);
        [xvals_sorted, ind] = unique(xvals_sorted);
        yvals_sorted = yvals_sorted(ind);
        try
            F = griddedInterpolant(xvals_sorted,yvals_sorted);
            T.half_peak_size(i) = F(T.min_spikes_ON(i)/2);
        catch
            T.half_peak_size(i) = nan;
        end

%         T.half_peak_size(i) = interp1(R.spikes_stim_mean{i}(1:ind_ON_min),R.spot_sizes{i}(1:ind_ON_min),...
%             T.min_spikes_ON(i)/2,"linear");
    end
end

save(['result_tables' filesep 'NF1_SMS_results'],'T');

%% separate sub-tables
ind = strcmp(T.cell_type,'ON alpha');
T_ON = T(ind,:);
ind = strcmp(T.cell_type,'OFF transient alpha');
T_OFFtr = T(ind,:);
ind = strcmp(T.cell_type,'OFF sustained alpha');
T_OFFsus = T(ind,:);

%% run some linear mixed-effects models to account for individual differences between animals
model_formula = 'peak_size_ON~genotype+sex+which_eye+quadrant+(1|animal_id)+(genotype-1|animal_id)+(sex-1|animal_id)+(quadrant-1|animal_id)+(which_eye-1|animal_id)';
lme_peak_size_ON = fitlme(T_ON,model_formula);

model_formula = 'peak_size_ON~genotype+sex+quadrant+(1|animal_id)+(genotype-1|animal_id)+(sex-1|animal_id)+(quadrant-1|animal_id)+(genotype:quadrant-1|animal_id)';
lme_peak_size_ON_w_interaction = fitlme(T_ON,model_formula);

model_formula = 'peak_size_ON~sex+quadrant+(1|animal_id)+(sex-1|animal_id)+(quadrant-1|animal_id)';
lme_peak_size_ON_simpler = fitlme(T_ON,model_formula);

model_formula = 'peak_size_ON~sex+(1|animal_id)+(sex-1|animal_id)';
lme_peak_size_ON_noquad = fitlme(T_ON,model_formula);

model_formula = 'peak_size_ON~quadrant+(1|animal_id)+(quadrant-1|animal_id)';
lme_peak_size_ON_nosex = fitlme(T_ON,model_formula);

model_formula = 'peak_spikes_ON~genotype+sex+quadrant+which_eye+(1|animal_id)+(genotype-1|animal_id)+(sex-1|animal_id)+(quadrant-1|animal_id)+(which_eye-1|animal_id)';
lme_peak_spikes_ON = fitlme(T_ON,model_formula);

model_formula = 'baseline_FR~genotype+sex+quadrant+which_eye+(1|animal_id)+(genotype-1|animal_id)+(sex-1|animal_id)+(quadrant-1|animal_id)+(which_eye-1|animal_id)';
lme_baseline_FR = fitlme(T_ON,model_formula);

model_formula = 'peak_FR~genotype+sex+which_eye+quadrant+(1|animal_id)+(genotype-1|animal_id)+(sex-1|animal_id)+(quadrant-1|animal_id)+(which_eye-1|animal_id)';
lme_max_FR = fitlme(T_ON,model_formula);

model_formula = 'SI~genotype+sex+which_eye+quadrant+(1|animal_id)+(genotype-1|animal_id)+(sex-1|animal_id)+(quadrant-1|animal_id)+(which_eye-1|animal_id)';
lme_SI = fitlme(T_ON,model_formula);

ok_ind = ~isnan(T_ON.half_peak_size);
model_formula = 'half_peak_size~genotype+sex+which_eye+quadrant+(1|animal_id)+(genotype-1|animal_id)+(sex-1|animal_id)+(quadrant-1|animal_id)+(which_eye-1|animal_id)';
lme_half_peak_size_ON = fitlme(T_ON(ok_ind,:),model_formula);

%% plot some of the coefficients
figure;
var_names = categorical(lme_peak_size_ON.CoefficientNames(2:end));
bar(var_names, lme_peak_size_ON.Coefficients.Estimate(2:end), 'FaceColor',[0.5,0.5,0.5],'EdgeColor','k');
set(gca, 'TickLabelInterpreter', 'none')
hold('on');
errorbar(var_names, lme_peak_size_ON.Coefficients.Estimate(2:end), ...
    lme_peak_size_ON.Coefficients.SE(2:end)*1.96, 'k.');
ylabel('Coefficient');
title('Effect on peak spot size (ON alpha)');
hold('off');

figure;
var_names = categorical(lme_half_peak_size_ON.CoefficientNames(2:end));
bar(var_names, lme_half_peak_size_ON.Coefficients.Estimate(2:end), 'FaceColor',[0.5,0.5,0.5],'EdgeColor','k');
set(gca, 'TickLabelInterpreter', 'none')
hold('on');
errorbar(var_names, lme_half_peak_size_ON.Coefficients.Estimate(2:end), ...
    lme_half_peak_size_ON.Coefficients.SE(2:end)*1.96, 'k.');
ylabel('Coefficient');
title('Effect on half peak spot size (ON alpha)');
hold('off');

figure;
var_names = categorical(lme_peak_spikes_ON.CoefficientNames(2:end));
bar(var_names, lme_peak_spikes_ON.Coefficients.Estimate(2:end), 'FaceColor',[0.5,0.5,0.5],'EdgeColor','k');
set(gca, 'TickLabelInterpreter', 'none')
hold('on');
errorbar(var_names, lme_peak_spikes_ON.Coefficients.Estimate(2:end), ...
    lme_peak_spikes_ON.Coefficients.SE(2:end)*1.96, 'k.');
ylabel('Coefficient');
title('Effect on peak spike count (ON alpha)');
hold('off');

figure;
var_names = categorical(lme_SI.CoefficientNames(2:end));
bar(var_names, lme_SI.Coefficients.Estimate(2:end), 'FaceColor',[0.5,0.5,0.5],'EdgeColor','k');
set(gca, 'TickLabelInterpreter', 'none')
hold('on');home
errorbar(var_names, lme_SI.Coefficients.Estimate(2:end), ...
    lme_SI.Coefficients.SE(2:end)*1.96, 'k.');
ylabel('Coefficient');
title('Effect on surround suppression index (ON alpha)');
hold('off');
