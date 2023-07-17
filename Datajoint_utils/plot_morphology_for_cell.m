function plot_morphology_for_cell(cellname, base_folder, save_plot)
try
    if nargin < 2 || isempty(base_folder)
        base_folder = '~/OneDrive - Northwestern University/dAC_images/done/';
    end
    if nargin < 3
        save_plot = true;
    end

    cell_dir = sprintf("%s%s%s", base_folder, cellname, filesep);
    proj_image = imread(sprintf('%s%s_maxProj.tif', cell_dir, cellname));

    load(sprintf('%sarborData.mat',cell_dir), 'appdata');

    f = figure;
    subplot(2,2,1);
    scatter(appdata.nodes_flattened(:,1),appdata.nodes_flattened(:,2),'ko','filled');
    axis('equal');
    xlabel('X (µm)')
    ylabel('Y (µm)')
    subplot(2,2,2);
    imagesc(flipud(proj_image));
    colormap('gray');
    subplot(2,2,3);
    hold('on');
    scatter(appdata.nodes_flattened(:,1),appdata.nodes_flattened(:,3),'ko','filled')
    line([0, max(appdata.nodes_flattened(:,1))],[appdata.lower_surface_z appdata.lower_surface_z],'Color','r','linestyle','--')
    line([0, max(appdata.nodes_flattened(:,1))],[appdata.upper_surface_z appdata.upper_surface_z],'Color','r','linestyle','--')
    xlabel('X (µm)')
    ylabel('Depth (µm)')
    ylim([0, appdata.upper_surface_z * 1.5])
    hold('off');
    subplot(2,2,4);
    hold('on');
    plot(appdata.strat_x,appdata.strat_y_norm,'k-','LineWidth',2);
    line([0 0], [0 1], 'Color','r','linestyle','--');
    line([1 1], [0 1], 'Color','r','linestyle','--');
    xlim([-2 2]);
    xlabel('IPL depth (normalized)')
    ylabel('Dendrite density (normalized)')
    hold('off');

    if save_plot
        saveas(f,sprintf('%smorph_summary.png',cell_dir));
        close(f);
    end
catch ME
    cellname
    disp(ME.message);
end