function plot_GLUT1_vs_stim_on_time(conditions_table)
T_neg = conditions_table(strcmp(conditions_table.gfp,'F'),:);
T_pos = conditions_table(strcmp(conditions_table.gfp,'T'),:);

cat_mean_neg = T_neg.glut1_ratio_mean;
cat_sem_neg = T_neg.glut1_ratio_sem;
cat_mean_pos = T_pos.glut1_ratio_mean;
cat_sem_pos = T_pos.glut1_ratio_sem;

stim_on_time_neg = categorical(cellstr(strcat(num2str(T_neg.stim_on_time), '_eGFP-')));
stim_on_time_pos = categorical(cellstr(strcat(num2str(T_pos.stim_on_time), '_eGFP+')));

figure;
bar(stim_on_time_neg,cat_mean_neg,'FaceColor',[0.5 0.5 0.5],'FaceAlpha',0.5);
set(gca,'TickLabelInterpreter','none');
hold("on")
errorbar(stim_on_time_neg,cat_mean_neg,cat_sem_neg,'k.');
for i=1:length(stim_on_time_neg)
    scatter(stim_on_time_neg(i),T_neg.glut1_ratio_all{i},'filled','MarkerFaceColor',[0.5 0.5 0.5]);
end

bar(stim_on_time_pos,cat_mean_pos,'FaceColor','g','FaceAlpha',0.5);
errorbar(stim_on_time_pos,cat_mean_pos,cat_sem_pos,'g.');
for i=1:length(stim_on_time_pos)
    scatter(stim_on_time_pos(i),T_pos.glut1_ratio_all{i},'filled','MarkerFaceColor','g');
end

hold("off")



