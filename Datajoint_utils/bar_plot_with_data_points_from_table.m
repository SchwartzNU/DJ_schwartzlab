function bar_plot_with_data_points_from_table(T)
x_var = T.Properties.VariableNames{1};
y_var = T.Properties.VariableNames{2};
X = T.(x_var);
Y = T.(y_var);
X_cat = categorical(cellstr(X));

N = height(T);

figure;
mean_vals = zeros(N,1);
sem_vals = zeros(N,1);
for i=1:N
   mean_vals(i) = mean(Y{i});
   sem_vals(i) = std(Y{i}./sqrt(length(Y{i})-1));
   plot(categorical(cellstr(X{i})),Y{i},'kx','LineWidth',2)
end
bar(X_cat,mean_vals,'FaceColor',[0.7 0.7 0.7]);
hold('on')
xlabel(x_var,'Interpreter','none');
ylabel(y_var,'Interpreter','none');
errorbar(X_cat,mean_vals,sem_vals,'k.');
for i=1:N
   plot(categorical(cellstr(X{i})),Y{i},'kx','LineWidth',2)
end
hold('off');






