function axon_terminal_color_plotter(q)
s = fetch(q,'mask_image','pixel_color');

[rows,cols,N_frames] = size(s.mask_image);
M_RGB = zeros([size(s.mask_image), 3]);

for i=1:N_frames
    ind = find(s.mask_image(:,:,i));
    [r,c] = ind2sub([rows, cols],ind);    
    for j=1:length(ind)
        M_RGB(r(j),c(j),i,:) = s.pixel_color{i}(j,:);
    end
    
end

max_RGB(:,:,1) = squeeze(max(M_RGB(:,:,:,1),[],3));
max_RGB(:,:,2) = squeeze(max(M_RGB(:,:,:,2),[],3));
max_RGB(:,:,3) = squeeze(max(M_RGB(:,:,:,3),[],3));

max_RGB = log(max_RGB+1);
max_val = max(max_RGB,[],'all');
max_RGB = max_RGB./max_val;
zero_pix = sum(max_RGB,3)==0;


h = imshow(max_RGB);
set(gca, 'Color', [1 1 1]) 
set(h, 'AlphaData', ~zero_pix) 
