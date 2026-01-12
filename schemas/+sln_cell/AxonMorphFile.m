%{
#Store swc files of axons of RGC axon terminals in brain that are traced, can be multiple files
->sln_image.AxonInBrain
---
swc_files: blob@raw #trees of the traced axon

%}
classdef AxonMorphFile < dj.Manual
methods (Static)
    function read_swcs_from_folder(folder, image_id)
        q.image_id = image_id;
        axonIn = fetch(sln_image.AxonInBrain & q);
        if (isempty(axonIn))
            error('This axonal image %d cannot be found!\n', image_id);
        end

        files = dir(folder);
        files = files(~[files.isdir]);
        %swc_num = 0;
        swc_list = {};

        for i = 1:numel(files)
            if (endswith(files(i).name, '.swc'))
                swc_list{end+1} = files(i).name;
            end
        end

    end
end
end