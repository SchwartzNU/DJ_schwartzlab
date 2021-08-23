function psth = makePSTHfromPSTH(spotSizes, varargin)

[~,s] = min(abs(bsxfun(@minus,varargin{1},spotSizes)),[],1);
%what spot size to interpolate from?
%uses nearest neighbor

[nX,nS] = size(varargin{2});
psth = {varargin{2}( s + nX*((1:nS)'-1) )};



end