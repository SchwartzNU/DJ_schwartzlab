function [] = showImage(cell_identifier,morph_only)
if nargin<2
    morph_only = false;
end
if isnumeric(cell_identifier)
    match = sln_cell.Cell & sprintf('cell_unid=%d',cell_identifier);
else
    match = sln_cell.Cell * sln_cell.CellName & sprintf('cell_name="%s"',cell_identifier);
end

if match.count == 1
    cell_unid = fetch1(match,'cell_unid');
    morph_data = sln_image.RetinalCellMorphology & sprintf('cell_unid=%d',cell_identifier);
    if morph_data.count == 1
        morph_data_struct = fetch(morph_data,'nodes_flattened','strat_x','strat_y_norm','lower_surface_z','upper_surface_z');
        morph_data_found = true;
    else
        fprintf('No morphology data found for cell %d\n',cell_unid);
        morph_data_found = false;
    end

    image_data_found = false;
    if ~morph_only
        image_match = sln_image.Image * sln_image.RetinalCellImage & sprintf('cell_unid=%d',cell_identifier);
        if image_match.count > 1
            fprintf('Multiple matching images found for cell %d\n',cell_unid);
            fprintf('Image chooser needs to be implemented.\n');
        elseif image_match.count == 1
            image_data_found = true;
            disp('Fetching image data...');
            image_data = fetch(image_match,'*');
            disp('Done.');
            cell_fill_id = fetch1(sln_image.ChannelType & 'channel_content="cell fill"', 'channel_type_id');
            genetic_or_viral_id = fetch1(sln_image.ChannelType & 'channel_content="genetic or viral label"', 'channel_type_id');
            chat_id = fetch1(sln_image.ChannelType & 'channel_content="ChAT"', 'channel_type_id');
            cell_fill_side = [];
            genetic_or_viral_side = [];
            chat_side = [];
            for i=1:image_data.n_channels
                ch_field = sprintf('ch%d_type',i);                
                switch image_data.(ch_field) %TODO could have multiple cells filled
                    case cell_fill_id
                        cell_fill_enface = flipud(max(image_data.raw_image(:,:,:,i), [], 3));
                        cell_fill_side = flipud(squeeze(max(image_data.raw_image(:,:,:,i), [], 1))');
                    case genetic_or_viral_id
                        genetic_or_viral_enface = flipud(max(image_data.raw_image(:,:,:,i), [], 3));
                        genetic_or_viral_side = flipud(squeeze(max(image_data.raw_image(:,:,:,i), [], 1))');
                    case chat_id
                        chat_side = flipud(squeeze(max(image_data.raw_image(:,:,:,i), [], 1))');
                end

            end
        else
            fprintf('No matching image found for cell %d\n',cell_unid);
        end
    end

    %plotting parts
    if ~morph_only
        empty_parts = isempty(cell_fill_side) + isempty(genetic_or_viral_side) + isempty(chat_side);        
        n_cols = 2*(3-empty_parts);
        n_rows = 3;
        f_raw = figure;
        tiledlayout(n_rows,n_cols,'TileSpacing','tight','parent',f_raw);

        if ~isempty(cell_fill_side)
            %cell fill en face
            nexttile([2 2]);
            axis('image');
            imagesc(cell_fill_enface);
            title('Cell fill');
        end

        if ~isempty(genetic_or_viral_side)
            %genetic_or_viral en face
            nexttile([2 2]);
            axis('image');
            imagesc(log(double(genetic_or_viral_enface)));
            title('Genetic or viral label');
        end

        if ~isempty(cell_fill_side)
            %cell fill side
            nexttile([1 2]);
            imagesc(cell_fill_side);
        end

        if ~isempty(genetic_or_viral_side)
            %genetic_or_viral side
            nexttile([1 2]);
            imagesc(genetic_or_viral_side);
        end

        if ~isempty(chat_side)
            %chat_side side
            nexttile([1 2]);            
            imagesc(chat_side);
            title('ChAT');
        end

    end
    if morph_data_found
        n_rows = 3;
        n_cols = 3;
        f_morph = figure;
        tiledlayout(n_rows,n_cols,'TileSpacing','tight','parent',f_morph);

        %skeleton en face
        nexttile([2 2]);
        scatter(morph_data_struct.nodes_flattened(:,1),morph_data_struct.nodes_flattened(:,2),'ko','filled');
        axis('image');
        xlabel('X (µm)')
        ylabel('Y (µm)')

        %side view of skeleton
        nexttile([1 2]);
        hold('on');
        scatter(morph_data_struct.nodes_flattened(:,1),morph_data_struct.nodes_flattened(:,3),'ko','filled')
        line([0, max(morph_data_struct.nodes_flattened(:,1))],[morph_data_struct.lower_surface_z morph_data_struct.lower_surface_z],'Color','r','linestyle','--')
        line([0, max(morph_data_struct.nodes_flattened(:,1))],[morph_data_struct.upper_surface_z morph_data_struct.upper_surface_z],'Color','r','linestyle','--')
        xlabel('X (µm)')
        ylabel('Depth (µm)')
        ylim([0, morph_data_struct.upper_surface_z * 1.5])
        hold('off');

        %stratification profile
        nexttile([3 1]);
        hold('on');
        plot(morph_data_struct.strat_x,morph_data_struct.strat_y_norm,'k-','LineWidth',2);
        line([0 0], [0 1], 'Color','r','linestyle','--');
        line([1 1], [0 1], 'Color','r','linestyle','--');
        xlim([-2 2]);
        xlabel('IPL depth (normalized)')
        ylabel('Dendrite density (normalized)')
        hold('off');
    end
  

else
    fprintf('No matching cell found\n');
end


