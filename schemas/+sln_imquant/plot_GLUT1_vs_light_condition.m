function plot_GLUT1_vs_light_condition(conditions_table)
T_neg = conditions_table(strcmp(conditions_table.gfp,'F'),:);
T_pos = conditions_table(strcmp(conditions_table.gfp,'T'),:);

cat_mean_neg = T_neg.glut1_ratio_mean;
cat_sem_neg = T_neg.glut1_ratio_sem;
cat_mean_pos = T_pos.glut1_ratio_mean;
cat_sem_pos = T_pos.glut1_ratio_sem;

light_conds_neg = categorical(strcat(T_neg.light_condition_name, '_eGFP-'));
light_conds_pos = categorical(strcat(T_pos.light_condition_name, '_eGFP+'));

figure;
bar(light_conds_neg,cat_mean_neg,'FaceColor',[0.5 0.5 0.5],'FaceAlpha',0.5);
set(gca,'TickLabelInterpreter','none');
hold("on")
errorbar(light_conds_neg,cat_mean_neg,cat_sem_neg,'k.');
scatter(light_conds_neg(1),T_neg.glut1_ratio_all{1},'filled','MarkerFaceColor',[0.5 0.5 0.5]);
scatter(light_conds_neg(2),T_neg.glut1_ratio_all{2},'filled','MarkerFaceColor',[0.5 0.5 0.5]);

bar(light_conds_pos,cat_mean_pos,'FaceColor','g','FaceAlpha',0.5);
errorbar(light_conds_pos,cat_mean_pos,cat_sem_pos,'g.');
scatter(light_conds_pos(1),T_pos.glut1_ratio_all{1},'filled','MarkerFaceColor','g');
scatter(light_conds_pos(2),T_pos.glut1_ratio_all{2},'filled','MarkerFaceColor','g');

hold("off")




