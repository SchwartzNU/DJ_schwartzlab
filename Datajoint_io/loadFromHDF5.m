
fpath = sprintf('%s%s.h5', getenv('RAW_DATA_FOLDER'), fname);
info = h5info(fpath, '/');

globalAttributes = info.Attributes; %<- symphony major version, version, and compression
experiment = info.Groups;
experimentProperties = experiment.Groups(3).Attributes;
%not clear that resources includes anything useful...
retinas = cell2mat(arrayfun( @(x) struct('info',...
    h5info(fpath, x.Value{1}),...
    'Link',x.Name), experiment.Groups(5).Links, 'UniformOutput', false));
epochGroups = struct('uuid',{},'label',{},'blocks',{},'retina',{},'cell',{});
count = 0;
for n = 1:numel(retinas)
    retinas(n).Name = retinas(n).info.Attributes(2).Value;
    retinas(n).genotype = retinas(n).info.Groups(3).Attributes(1).Value;
    retinas(n).orientation = retinas(n).info.Groups(3).Attributes(3).Value;
    retinas(n).experimenter = retinas(n).info.Groups(3).Attributes(4).Value;
    retinas(n).eye = retinas(n).info.Groups(3).Attributes(2).Value;
    
    retinas(n).cells = cell2mat(arrayfun(@(x) struct('info',...
        h5info(fpath, x.Value{1})),...
        retinas(n).info.Groups(5).Links,'UniformOutput',false));
    for m = 1:numel(retinas(n).cells)
        retinas(n).cells(m).Name = retinas(n).cells(m).info.Attributes(4).Value;
        retinas(n).cells(m).online_label = retinas(n).cells(m).info.Groups(4).Attributes(4).Value;
        retinas(n).cells(m).location = retinas(n).cells(m).info.Groups(4).Attributes(3).Value;
        
        for l = 1:numel(retinas(n).cells(m).info.Groups(1).Groups)
            epochGroup = retinas(n).cells(m).info.Groups(1).Groups(l);
            uuid = epochGroup.Attributes(1).Value;
            if ~ismember(uuid,{epochGroups(:).uuid})
                g = struct('uuid',uuid,'label',epochGroup.Attributes(4).Value,'retina',retinas(n).Name,'cell',retinas(n).cells(m).Name);
                
                %now we get to the epoch blocks:
                g.blocks = struct('protocol',{},'parameters',{},'epochs',{});
                for k = 1:numel(epochGroup.Groups(1).Groups)
                    block = epochGroup.Groups(1).Groups(k);
                    g.blocks(k).protocol =  block.Attributes(4).Value;
                    g.blocks(k).parameters = block.Groups(2).Attributes;
                    g.blocks(k).epochs = struct('parameters',{},'recording_links',{});
                    for j = 1:numel(block.Groups(1).Groups)
                        epoch = block.Groups(1).Groups(j);
                        g.blocks(k).epochs(j).parameters = epoch.Groups(2).Attributes;
                        g.blocks(k).epochs(j).recording_links = {epoch.Groups(3).Groups(:).Name};
                        %epoch.Groups(3).Groups(1).sampleRate ...
                        %sampleRateUnits,
                        %inputTimeDotNetDateTimeOffsetTicks
                    end
                
                end
                
                epochGroups(l+count) = g;
            else
                warning('skipped!');
            end
            
        end
        count = length(epochGroups);
        %epoch groups: retinas(n).cells(m).info.Groups(1)
    end
%     cellLinks = retinas(n).info.Groups(5).Links;
    
end
epochs = cell2mat(arrayfun( @(x)cell2mat({x.blocks(:).epochs}), epochGroups,'uniformoutput',false));
channel1 = arrayfun(@(x) x.recording_links{1}, epochs,'uniformoutput',false);
channel2 = arrayfun(@(x) x.recording_links{end}, epochs,'uniformoutput',false);
[channel2{arrayfun(@(x) length(x.recording_links)<2, epochs)}] = deal(nan);

%other epoch groups?
%epochGroup = experiment.Groups(2).Groups(:); %epochGroups
% g.uuid = epochGroup.Attributes(1).Value


% devices = experiment.Groups(1);
devices = cell2mat(arrayfun(@(x) struct('Name',x.Attributes(2).Value, 'Link', x.Name), experiment.Groups(1).Groups, 'UniformOutput', false));
%display with struct2table


