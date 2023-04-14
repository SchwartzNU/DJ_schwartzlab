%% Parameter for recompute or load results tables
recompute = false;

%% load the datagroups with the SMS data
load DataGroups/SMS_STZ_CA_alphas.mat;
dg_STZ = data_group;

load DataGroups/SMS_sham_CA_alphas.mat;
dg_sham = data_group;

%% Display the group statistics for the dataset
%STZ
animals = sln_animal.Animal & proj(dg_STZ,'source_id->cell_source');
males = animals & 'sex="Male"';
females = animals & 'sex="Female"';
eyes = sln_animal.Animal * sln_animal.Eye & proj(dg_STZ,'source_id->cell_source');

fprintf("STZ group\n");
fprintf("-----------\n");
fprintf("%d total animals\n", animals.count);
fprintf("%d male; %d female\n", males.count, females.count);
fprintf("%d total eyes\n", eyes.count);

cells = sln_cell.Cell * proj(sln_cell.RetinaQuadrant,'image_id->quad_image_id','*') * sln_cell.AssignType.current & proj(dg_STZ,'image_id->not_used');
all_types = unique(fetchn(cells, 'cell_type'));

fprintf("-----------\n");

fprintf("%d total cells\n", cells.count);
for i=1:length(all_types)
    thisType = cells & sprintf('cell_type="%s"', all_types{i});
    fprintf('%s: %d\n', all_types{i}, thisType.count);
end

fprintf("-----------\n");

%sham
animals = sln_animal.Animal & proj(dg_sham,'source_id->cell_source');
males = animals & 'sex="Male"';
females = animals & 'sex="Female"';
eyes = sln_animal.Animal * sln_animal.Eye & proj(dg_sham,'source_id->cell_source');

fprintf("Sham group\n");
fprintf("-----------\n");
fprintf("%d total animals\n", animals.count);
fprintf("%d male; %d female\n", males.count, females.count);
fprintf("%d total eyes\n", eyes.count);

cells = sln_cell.Cell * proj(sln_cell.RetinaQuadrant,'image_id->quad_image_id','*') * sln_cell.AssignType.current & proj(dg_sham,'image_id->not_used');
all_types = unique(fetchn(cells, 'cell_type'));

fprintf("-----------\n");
fprintf("%d total cells\n", cells.count);
for i=1:length(all_types)
    thisType = cells & sprintf('cell_type="%s"', all_types{i});
    fprintf('%s: %d\n', all_types{i}, thisType.count);
end
%% set up table to hold results
if recompute
    q = sln_results.DatasetSMSCA & proj(dg_STZ);
    R_STZ = sln_results.toMatlabTable(q);
    N = height(R_STZ);

    T_STZ = table('Size',[N,18],'VariableTypes',...
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
        {'glucose_condition', ...
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

    q = sln_results.DatasetSMSCA & proj(dg_sham);
    R_sham = sln_results.toMatlabTable(q);
    N = height(R_sham);

    T_sham = table('Size',[N,18],'VariableTypes',...
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
        {'glucose_condition', ...
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
end

%% get SMS results data for all of them
if recompute
    %STZ
    animals = sln_animal.Animal & proj(dg_STZ,'source_id->cell_source');
    cells = sln_cell.Cell * proj(sln_cell.RetinaQuadrant,'image_id->quad_image_id','*') * sln_cell.AssignType.current & proj(dg_STZ,'image_id->not_used');

    N = height(T_STZ);
    for i=1:N
        fprintf('Collecting data for cell %d of %d\n', i, N);
        thisCell = fetch(cells & ...
            sprintf('file_name="%s"', R_STZ.file_name{i}) & ...
            sprintf('source_id="%d"', R_STZ.source_id(i)), '*');
        thisAnimal = fetch(animals & sprintf('animal_id=%d',thisCell.animal_id), '*');
        T_STZ.glucose_condition(i) = 'STZ';
        T_STZ.sex(i) = thisAnimal.sex;
        T_STZ.animal_id(i) = sprintf('DJID_%d', thisAnimal.animal_id);
        T_STZ.which_eye(i) = thisCell.side;
        T_STZ.quadrant(i) = thisCell.quadrant;
        T_STZ.cell_type(i) = thisCell.cell_type;

        T_STZ.peak_FR(i) = max(R_STZ.sms_psth{i}(:));
        [T_STZ.peak_spikes_ON(i), ind_ON_max] = max(R_STZ.spikes_stim_mean{i});
        T_STZ.peak_size_ON(i) = R_STZ.spot_sizes{i}(ind_ON_max);
        [T_STZ.peak_spikes_OFF(i), ind] = max(R_STZ.spikes_tail_mean{i});
        T_STZ.peak_size_OFF(i) = R_STZ.spot_sizes{i}(ind);
        [T_STZ.min_spikes_ON(i), ind_ON_min] = min(R_STZ.spikes_stim_mean{i});
        T_STZ.min_size_ON(i) = R_STZ.spot_sizes{i}(ind_ON_min);
        [T_STZ.min_spikes_OFF(i), ind] = min(R_STZ.spikes_tail_mean{i});
        T_STZ.min_size_OFF(i) = R_STZ.spot_sizes{i}(ind);
        T_STZ.baseline_FR(i) = R_STZ.baseline_rate_hz(i);
        spikes_ON_large = R_STZ.spikes_stim_mean{i}(end);
        if strcmp(thisCell.cell_type, 'ON alpha')            
            T_STZ.SI(i) = (T_STZ.peak_spikes_ON(i) - spikes_ON_large) / (T_STZ.peak_spikes_ON(i) + spikes_ON_large);

            xvals = R_STZ.spikes_stim_mean{i}(1:ind_ON_max);
            yvals = R_STZ.spot_sizes{i}(1:ind_ON_max);
            [xvals_sorted, ind] = sort(xvals,'ascend');
            yvals_sorted = yvals(ind);
            [xvals_sorted, ind] = unique(xvals_sorted);
            yvals_sorted = yvals_sorted(ind);
            try
                F = griddedInterpolant(xvals_sorted,yvals_sorted);
                T_STZ.half_peak_size(i) = F(T_STZ.peak_spikes_ON(i)/2);
            catch
                T_STZ.half_peak_size(i) = nan;
            end
        else
            peak_suppression = T_STZ.baseline_FR(i) - T_STZ.min_spikes_ON(i);
            large_suppression = T_STZ.baseline_FR(i) - spikes_ON_large;
            T_STZ.SI(i) = (peak_suppression - large_suppression) / (peak_suppression + large_suppression);

            %T_STZ.SI(i) = nan;

            xvals = R_STZ.spikes_stim_mean{i}(1:ind_ON_min);
            yvals = R_STZ.spot_sizes{i}(1:ind_ON_min);
            [xvals_sorted, ind] = sort(xvals,'ascend');
            yvals_sorted = yvals(ind);
            [xvals_sorted, ind] = unique(xvals_sorted);
            yvals_sorted = yvals_sorted(ind);
            try
                F = griddedInterpolant(xvals_sorted,yvals_sorted);
                T_STZ.half_peak_size(i) = F(T_STZ.min_spikes_ON(i)/2);
            catch
                T_STZ.half_peak_size(i) = nan;
            end

        end
    end

    %sham
    animals = sln_animal.Animal & proj(dg_sham,'source_id->cell_source');
    cells = sln_cell.Cell * proj(sln_cell.RetinaQuadrant,'image_id->quad_image_id','*') * sln_cell.AssignType.current & proj(dg_sham,'image_id->not_used');

    N = height(T_sham);
    for i=1:N
        fprintf('Collecting data for cell %d of %d\n', i, N);
        thisCell = fetch(cells & ...
            sprintf('file_name="%s"', R_sham.file_name{i}) & ...
            sprintf('source_id="%d"', R_sham.source_id(i)), '*');
        thisAnimal = fetch(animals & sprintf('animal_id=%d',thisCell.animal_id), '*');
        T_sham.glucose_condition(i) = 'sham';
        T_sham.sex(i) = thisAnimal.sex;
        T_sham.animal_id(i) = sprintf('DJID_%d', thisAnimal.animal_id);
        T_sham.which_eye(i) = thisCell.side;
        T_sham.quadrant(i) = thisCell.quadrant;
        T_sham.cell_type(i) = thisCell.cell_type;

        T_sham.peak_FR(i) = max(R_sham.sms_psth{i}(:));
        [T_sham.peak_spikes_ON(i), ind_ON_max] = max(R_sham.spikes_stim_mean{i});
        T_sham.peak_size_ON(i) = R_sham.spot_sizes{i}(ind_ON_max);
        [T_sham.peak_spikes_OFF(i), ind] = max(R_sham.spikes_tail_mean{i});
        T_sham.peak_size_OFF(i) = R_sham.spot_sizes{i}(ind);
        [T_sham.min_spikes_ON(i), ind_ON_min] = min(R_sham.spikes_stim_mean{i});
        T_sham.min_size_ON(i) = R_sham.spot_sizes{i}(ind_ON_min);
        [T_sham.min_spikes_OFF(i), ind] = min(R_sham.spikes_tail_mean{i});
        T_sham.min_size_OFF(i) = R_sham.spot_sizes{i}(ind);
        T_sham.baseline_FR(i) = R_sham.baseline_rate_hz(i);
        spikes_ON_large = R_sham.spikes_stim_mean{i}(end);
        if strcmp(thisCell.cell_type, 'ON alpha')
            T_sham.SI(i) = (T_sham.peak_spikes_ON(i) - spikes_ON_large) / (T_sham.peak_spikes_ON(i) + spikes_ON_large);

            xvals = R_sham.spikes_stim_mean{i}(1:ind_ON_max);
            yvals = R_sham.spot_sizes{i}(1:ind_ON_max);
            [xvals_sorted, ind] = sort(xvals,'ascend');
            yvals_sorted = yvals(ind);
            [xvals_sorted, ind] = unique(xvals_sorted);
            yvals_sorted = yvals_sorted(ind);
            try
                F = griddedInterpolant(xvals_sorted,yvals_sorted);
                T_sham.half_peak_size(i) = F(T_sham.peak_spikes_ON(i)/2);
            catch
                T_sham.half_peak_size(i) = nan;
            end
        else
            peak_suppression = T_sham.baseline_FR(i) - T_sham.min_spikes_ON(i);
            large_suppression = T_sham.baseline_FR(i) - spikes_ON_large;
            T_sham.SI(i) = (peak_suppression - large_suppression) / (peak_suppression + large_suppression);


            xvals = R_sham.spikes_stim_mean{i}(1:ind_ON_min);
            yvals = R_sham.spot_sizes{i}(1:ind_ON_min);
            [xvals_sorted, ind] = sort(xvals,'ascend');
            yvals_sorted = yvals(ind);
            [xvals_sorted, ind] = unique(xvals_sorted);
            yvals_sorted = yvals_sorted(ind);
            try
                F = griddedInterpolant(xvals_sorted,yvals_sorted);
                T_sham.half_peak_size(i) = F(T_sham.min_spikes_ON(i)/2);
            catch
                T_sham.half_peak_size(i) = nan;
            end

        end
    end

    T = [T_STZ; T_sham];
    save(['result_tables' filesep 'SMS_STZ_and_sham_results'],'T');
else
    load(['result_tables' filesep 'SMS_STZ_and_sham_results'],'T');
end
%% separate sub-tables
ind = strcmp(T.cell_type,'ON alpha');
T_ON = T(ind,:);
ind = strcmp(T.cell_type,'OFF sustained alpha');
T_OFF = T(ind,:);

%% run some linear mixed-effects models to account for individual differences between animals
model_formula = 'peak_size_ON~glucose_condition+quadrant+glucose_condition*quadrant+(glucose_condition*quadrant-1|animal_id)+(1|animal_id)+(glucose_condition-1|animal_id)+(quadrant-1|animal_id)';
lme_peak_size_ON = fitlme(T_ON,model_formula);

model_formula = 'min_size_OFF~glucose_condition+quadrant+glucose_condition*quadrant+(glucose_condition*quadrant-1|animal_id)+(1|animal_id)+(glucose_condition-1|animal_id)+(quadrant-1|animal_id)';
lme_min_size_OFF = fitlme(T_OFF,model_formula);

% model_formula = 'peak_spikes_ON~glucose_condition+quadrant+(1|animal_id)+(glucose_condition-1|animal_id)+(quadrant-1|animal_id)';
% lme_peak_spikes_ON = fitlme(T_ON,model_formula);

model_formula = 'peak_spikes_ON~glucose_condition+quadrant+glucose_condition*quadrant+(glucose_condition*quadrant-1|animal_id)+(1|animal_id)+(glucose_condition-1|animal_id)+(quadrant-1|animal_id)';
lme_peak_spikes_ON = fitlme(T_ON,model_formula);

model_formula = 'min_spikes_OFF~glucose_condition+quadrant+glucose_condition*quadrant+(glucose_condition*quadrant-1|animal_id)+(1|animal_id)+(glucose_condition-1|animal_id)+(quadrant-1|animal_id)';
lme_min_spikes_OFF = fitlme(T_OFF,model_formula);

model_formula = 'SI~glucose_condition+quadrant+glucose_condition*quadrant+(glucose_condition*quadrant-1|animal_id)+(1|animal_id)+(glucose_condition-1|animal_id)+(quadrant-1|animal_id)';
lme_SI_ON = fitlme(T_ON,model_formula);

model_formula = 'SI~glucose_condition+quadrant+glucose_condition*quadrant+(glucose_condition*quadrant-1|animal_id)+(1|animal_id)+(glucose_condition-1|animal_id)+(quadrant-1|animal_id)';
lme_SI_OFF = fitlme(T_OFF,model_formula);

disp('Done!');

%% Display anovas

vars = whos;
for i=1:length(vars)
    if startsWith(vars(i).name,'lme_')
        fprintf('%s:\n',vars(i).name);
        eval([vars(i).name '.anova']);
    end
end


% %% plot some of the coefficients
% figure;
% var_names = categorical(lme_peak_size_ON.CoefficientNames(2:end));
% bar(var_names, lme_peak_size_ON.Coefficients.Estimate(2:end), 'FaceColor',[0.5,0.5,0.5],'EdgeColor','k');
% set(gca, 'TickLabelInterpreter', 'none')
% hold('on');
% errorbar(var_names, lme_peak_size_ON.Coefficients.Estimate(2:end), ...
%     lme_peak_size_ON.Coefficients.SE(2:end)*1.96, 'k.');
% ylabel('Δ peak (µm)');
% title('Effect on peak spot size (ON alpha)');
% hold('off');
% 
% figure;
% var_names = categorical(lme_half_peak_size_ON.CoefficientNames(2:end));
% bar(var_names, lme_half_peak_size_ON.Coefficients.Estimate(2:end), 'FaceColor',[0.5,0.5,0.5],'EdgeColor','k');
% set(gca, 'TickLabelInterpreter', 'none')
% hold('on');
% errorbar(var_names, lme_half_peak_size_ON.Coefficients.Estimate(2:end), ...
%     lme_half_peak_size_ON.Coefficients.SE(2:end)*1.96, 'k.');
% ylabel('Δ peak (µm)');
% title('Effect on half peak spot size (ON alpha)');
% hold('off');
% 
% figure;
% var_names = categorical(lme_peak_spikes_ON.CoefficientNames(2:end));
% bar(var_names, lme_peak_spikes_ON.Coefficients.Estimate(2:end), 'FaceColor',[0.5,0.5,0.5],'EdgeColor','k');
% set(gca, 'TickLabelInterpreter', 'none')
% hold('on');
% errorbar(var_names, lme_peak_spikes_ON.Coefficients.Estimate(2:end), ...
%     lme_peak_spikes_ON.Coefficients.SE(2:end)*1.96, 'k.');
% ylabel('Δ spike count');
% title('Effect on peak spike count (ON alpha)');
% hold('off');
% 
% figure;
% var_names = categorical(lme_SI.CoefficientNames(2:end));
% bar(var_names, lme_SI.Coefficients.Estimate(2:end), 'FaceColor',[0.5,0.5,0.5],'EdgeColor','k');
% set(gca, 'TickLabelInterpreter', 'none')
% hold('on');home
% errorbar(var_names, lme_SI.Coefficients.Estimate(2:end), ...
%     lme_SI.Coefficients.SE(2:end)*1.96, 'k.');
% ylabel('Δ SI');
% title('Effect on surround suppression index (ON alpha)');
% hold('off');




