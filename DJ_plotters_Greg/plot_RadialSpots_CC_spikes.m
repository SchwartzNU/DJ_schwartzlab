function required_fields = plot_RadialSpots_CC_spikes(R,ax)
if nargin < 1
    required_fields = {'spike_count_matrix_mean', 'spike_count_matrix_sem', ...
        'spot_dist', 'spot_ang'};
    return;
end

[theta, rho] = meshgrid(R.spot_ang, R.spot_dist);
theta = reshape(theta,[numel(theta), 1]);
rho = reshape(rho,[numel(rho), 1]);
[x, y] = pol2cart(theta, rho);
x = round(x);
y = round(y);
vals = zeros(size(x));
vals_err = zeros(size(x));

[N_ang, N_dist] = size(R.peak_matrix_mean);

R.spike_count_matrix_mean(R.spike_count_matrix_mean==0, 1) = nan;

for t=1:N_ang
    for r=1:N_dist
        ind = find(theta == R.spot_ang(t) & rho == R.spot_dist(r));
        vals(ind) = R.spike_count_matrix_mean(t, r);
        vals_err(ind) = R.spike_count_matrix_sem(t, r);        
    end
end

scatter(ax, x, y, 100, vals, "filled");
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
xlabel(ax, 'x (µm)')
ylabel(ax, 'y (µm)');
c = colorbar(ax);
c.Label.String = 'Spikes';