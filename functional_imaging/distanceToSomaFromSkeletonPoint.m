function D = distanceToSomaFromSkeletonPoint(image_fname, loc_xyz, soma_xyz)
%bwdistgeodesic

skel = tiffreadVolume(image_fname);
skel = skel>0;

mask = false(size(skel));

mask(soma_xyz(2)+1,soma_xyz(1)+1,soma_xyz(3)+1) = true;
dist = imChamferDistance3d(skel, mask);

D = dist(loc_xyz(2)+1,loc_xyz(1)+1,loc_xyz(3)+1);
