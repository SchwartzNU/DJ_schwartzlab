%{
#just add a tag for which slice is the first slice that has SC
-> sln_tissue.BrainSliceBatch
---
->sln_image.WholeBrainImage
start_point: enum('A', 'P', 'M', 'L')
%}

classdef SCstart < dj.Manual
    methods (Static)
        function safe_insert(mouse_id, slice_num, brain_num, point)
            key.animal_id = mouse_id;
            tissue = fetch(sln_tissue.Tissue * sln_tissue.BrainSliceBatch & key, 'slicing_orientation');
            if (isempty(tissue))
                error('Cannot find brain slice record of mouse %d!\n',mouse_id);
            end

            brain_q.tissue_id = tissue.tissue_id;
            brain_q.slide_num = slice_num;
            brain_q.brain_num = brain_num;
            wb = fetch(sln_image.WholeBrainImage & brain_q);
            if (isempty(wb))
                error('Cannot find s%d_b%d of mouse %d\n', slice_num, brain_num, mouse_id);
            end
            flag1 = strcmp(tissue.slicing_orientation, 'Coronal');
            flag2 = sum(strcmp(point, {'A', 'P'}));
            if (flag1~=flag2)
                error('Check the tissue slicing orientation and the input start point!\n');
            end

            key.ref_image_id = wb.ref_image_id;
            key.start_point = point;

            try
                insert(sln_tissue.SCstart, key);
                fprintf('Inserting successful: \n');
                disp(key);
            catch ME
                rethrow(ME);
            end
           
        end
    end
end