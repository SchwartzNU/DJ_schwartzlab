% function output = assignWholeBrainIm(imageid, tissueid, sliceN, brainN, midp1, midp2)
% %test if imageid and tissue id is valid
% query_1_str  = append('image_id = ', int2str(imgeId));
% query_1 = sln_image.Image & query_1_str;
% query_2_str = append('tissue_id = ', int2str(tissueid));
% query_2 = sln_tissue.BrainSliceBatch & query_2_str;
% 
% if (exists(query_1)==false)
%     fprintf('Image not exists in the database...')
%     output = -1;
%     return
% else
%     if (exists(query_2)==false)
%         fprintf('Brain slice batch not exist');
%         output = -1;
%     end
% end
% 
% %check if double input
% query_3 = sln_image.WholeBrainImage & append('image_id = ', imageid);
% if (exists(query_3))
%     output = -1;
%     fprintf('Image already exists in the whole brain image data sets!')
% end
% 
% %is there anyway to make this look smarter??
% inputstruct.tissue_id = tissueid;
% inputstruct.imageid = imageid;
% inputstruct.slide_num = sliceN;
% inputstruct.brain_num = brainN;
% 
% %calcultate slope and intercept of the line of the midline 
% inputstruct.midline_slope = (midp2(2)-midp1(2))/(midp2(1)-midp1(1));
% inputstruct.midline_intercept = midp1(2) - inputstruct.midline_slope*midp1(1);
% 
% %insert the struct bloc into whole brain image table
% try
%     C = dj.conn;
%     C.startTransaction;
%     insert(sln_tissue.WholeBrainImage, inputstruct);
%     C.commitTransaction;
%     output = 0;
% catch ME
%     output = -1;
%     C.cancelTransaction;
%      rethrow(ME)
% end
% end