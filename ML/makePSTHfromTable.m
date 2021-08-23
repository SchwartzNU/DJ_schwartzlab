function h = makePSTHfromTable(nt, varargin)
% nt is a vector of [pre, post] stim onset time points
% varargin is the data table

%TODO: this is going to be slow; make it class based with a single
%allocation


snt = sum(nt);
binlimits = [-nt(1) nt(2)]/1e2;

h = mean(cell2mat(arrayfun(@(sp, pre, stim) histcounts((cell2mat(sp)*.1 - pre)./(stim - pre), snt, 'binlimits',binlimits),...
    varargin{1}, varargin{2}, varargin{3}, 'UniformOutput', false)),1)*100;


%2spikes per 10ms -> 20 spikes per 100ms -> 200 spikes per sec


end