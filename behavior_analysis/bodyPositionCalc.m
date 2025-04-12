TimeSpentOtherWindows = R.body_s(:,2) + R.body_s(:,3);
AverageStrangers= ((R.body_s(:,2) + R.body_s(:,3))/2);
ProportionWindows = (R.body_s(:,1)./ TimeSpentOtherWindows);
sortedProportionWindows = sort(ProportionWindows);
subplot(1,3,1);
scatter(AverageStrangers, (R.body_s(:,1)))
ylabel('Mouse Preference (s) Towards Cagemate');
xlabel('Mouse Preference (s) Towards Stranger (average)');
ylim([0 130])
xlim([0 130])
hold on
plot([0 130], [0 130], '--')
meanProportions= mean(sortedProportionWindows)

[InvMean.h,InvMean.p,InvMean.ci,InvMean.stats] = ttest(R.body_s(:,1), AverageStrangers)



subplot(1,3,2);
scatter((1:length(R.body_s)),sortedProportionWindows, 'filled')
hold on
yline(0.5, '--')
hold on
ylim([0 1.5])
ylabel('Mouse Preference Proportion (s) Cagemate:Stranger');
xlabel('Mouse');
stdProportion= std(ProportionWindows)/(sqrt(length(R.body_s)));
errorbar((length(R.body_s)/2), (mean(sortedProportionWindows)), stdProportion,stdProportion,'s')
errorbar((length(R.body_s)/2), (mean(sortedProportionWindows)), stdProportion,stdProportion,'s')
hold off

subplot(1,3,3);
x = [1];
timeCagemateAve= (mean(R.body_s(:,1)));
timeStrangerAve= mean(AverageStrangers);
y = [mean(ProportionWindows)];
bar(x,y)
xlabel('Mouse Preference Proportion (s) Cagemate:Stranger');
hold on
errorbar(1, (mean(sortedProportionWindows)), stdProportion,stdProportion,'s')
ylim([0 1])
hold off



