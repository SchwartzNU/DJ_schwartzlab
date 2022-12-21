%{ NOT a datajoint table


%}
classdef ExperimentProtocols < handle

    properties
        key
        bool_types = {'logScaling', 'randomOrdering', 'alternatePatterns', 'annulusMode', 'doSubtraction'};
        canInsert = false;
    end
    
    methods (Access = ?sln_symphony.Experiment)
        function ret = insert(self,epoch_blocks,epochs)
            %setup 
            self.key = struct('epoch_blocks',epoch_blocks,'epochs',epochs);
            self.parseProjectorSettings();
            self.removeRedundantFields();
            self.convertToBool();
            self.makeSnakeCase();
            self.copyPrimaryKeys();
            
            % return;
            schema = sln_symphony.getSchema();
            %initiate transaction
            transacted = false;
            if schema.conn.inTransaction
                transacted = true;
            else
                schema.conn.startTransaction;
            end
            try
                [protocols,~,ind] = unique({self.key.epoch_blocks(:).protocol_name});
                protocols'
                %altering names of these protocols to make them shorter -
                %table names are too long otherwise
                for p=1:length(protocols)
                    cur_prot = protocols{p};
                    if contains(cur_prot, 'dynamic_clamp')
                        this_prot_ind = find(strcmp({self.key.epoch_blocks(:).protocol_name}, cur_prot));
                        cur_prot_new = strrep(cur_prot, 'dynamic_clamp_conductance', 'dynamic_clamp');
                        for i=1:length(this_prot_ind)
                            self.key.epoch_blocks(this_prot_ind(i)).protocol_name = cur_prot_new;
                        end
                        protocols{p} = cur_prot_new;
                    end             
                end
                existing_protocols = fetch(sln_symphony.Protocol & struct('protocol_name',protocols));
                missing_protocols = setdiff(protocols, {existing_protocols(:).protocol_name});
                if ~isempty(missing_protocols)
                    missing_text = sprintf('\n\t> %s',missing_protocols{:});
                    names_text = sprintf('''%s'',',missing_protocols{:});
                    missing_text = sprintf(...
                        '%s\nTo insert all, use:\n\tsln_symphony.Protocol().insert({%s}'');',...
                        missing_text,names_text(1:end-1));
                    error(['Protocols were missing from the database. '...
                        'You must manually insert these in '...
                        'the Protocol table or rename them in the key:%s'], missing_text); %#ok<SPERR>
                end
                
                table = sln_symphony.ExperimentEpochBlock();
                table.canInsert = true;
                for i=1:length(self.key.epoch_blocks) %deal with empty epoch_block end times
                    if isempty(self.key.epoch_blocks(i).epoch_block_end_time)
                        self.key.epoch_blocks(i).epoch_block_end_time = ...
                            datestr(datetime(self.key.epoch_blocks(1).epoch_block_start_time) + minutes(30), 'YYYY-mm-dd HH:MM:SS');
                        %defaults to 30 minutes after the start of the
                        %epoch block
                    end
                end
                table.insert(self.key.epoch_blocks);

                table = sln_symphony.ExperimentProjectorSettings();
                table.canInsert = true;
                table.insert(self.key.projector);

                table = sln_symphony.ExperimentLEDSettings();
                table.canInsert = true;
                table.insert(self.key.LEDs);
                
                table = sln_symphony.ExperimentEpoch();
                table.canInsert = true;
                table.insert(self.key.epochs);                
                
                success = true;
                for i=1:numel(protocols)
                  b = self.key.block_params(ind==i);
                  bi = [self.key.epoch_blocks(ind==i).epoch_block_id];

                  e = self.key.epoch_params(arrayfun(@(x) ismember(x.epoch_block_id, bi), self.key.epochs));

                  success = self.insertProtocol(changeCase(protocols{i},'upperCamel'), joinKeys(b), joinKeys(e)) && success;
                end
                if ~success
                  error('One or more protocols were not compatible with any existing tables in the database. Please confirm the new table definition and try again.');
                  % error out, to cancel transaction; prompt user to re-insert
                end
            catch ME
                if ~transacted
                    schema.conn.cancelTransaction;
                end
                rethrow(ME);
            end
            if ~transacted
                schema.conn.commitTransaction;
            end
            ret = true;
        end

        function success = insertProtocol(self, protocol_name, block_params, epoch_params)
          %get existing tables under the protocol name
          if contains(protocol_name,'AutoCenter')
            warning('Skipping AutoCenter');
            success=true;
            return %TODO: do we want to include autocenter??? the parameters are ridiculous
            %perhaps instead we should create separate tables for each auto center subcaategory?
          end
          if contains(protocol_name,'AlignmentCross')
            warning('Skipping AlignmentCross');
            success=true;
            return
          end
          tables = sln_symphony.getSchema().classNames;
          matching = startsWith(tables, ['sln_symphony.ExperimentProt', protocol_name])...
              & endsWith(tables, 'bp');
          success = false;
          emptyMatches = {};
          for match = tables(matching)
              char(match)
              b = feval(char(match));% <- gets an object of the class
              e = feval([match{1}(1:end-2), 'ep']);
              if b.allows(block_params, epoch_params) && e.allows(block_params, epoch_params)
                b.canInsert = true;
                b.insert(block_params, epoch_params);

                e.canInsert = true;
                e.insert(block_params, epoch_params);
                success = true;
                return
              elseif b.count == 0
                 emptyMatches = vertcat(emptyMatches{:}, char(match));
              end
          end
          %%we failed to insert. explain why:
          bt = warning('query','backtrace');
          warning('off','backtrace');
          warnStr = sprintf('Failed to match protocol %s', protocol_name);
          for match = tables(matching)
              b = feval(char(match));% <- gets an object of the class
              e = feval([match{1}(1:end-2), 'ep']);
              [a_b, e_b, m_b] = b.allows(block_params, epoch_params);
              [a_e, e_e, m_e] = e.allows(block_params, epoch_params);
              
              warnStr = sprintf('%s\n\tFor table %s:', warnStr, match{1}(1:end-2));
              if ~isempty(e_b)
                  warnStr = sprintf('%s\n\t\tExtra block parameter(s): %s', warnStr, strjoin(e_b, ', '));
              end
              if ~isempty(m_b)
                  warnStr = sprintf('%s\n\t\tMissing block parameter(s): %s', warnStr, strjoin(m_b, ', '));
              end
              if ~isempty(e_e)
                  warnStr = sprintf('%s\n\t\tExtra epoch parameter(s): %s', warnStr, strjoin(e_e, ', '));
              end
              if ~isempty(m_e)
                  warnStr = sprintf('%s\n\t\tMissing epoch parameter(s): %s', warnStr, strjoin(m_e, ', '));
              end
          end
          fprintf('\n');
          warning(warnStr);
                   
          
          if ~isempty(emptyMatches)
              %we probably mean to edit one of these
              if isa(emptyMatches, 'cell') && numel(emptyMatches) > 1
                  warning('Possible table match: %s',emptyMatches{:});
              else
                  c = char(emptyMatches);
                  edit(c);
                  edit(sprintf('%sep',c(1:end-2)));
              end
              return
          end
          loc = fileparts(which(class(self)));
          k = dir(fullfile(loc, ['ExperimentProt', protocol_name ,'*bp.m']));
          if ~isempty(k)
              matches = arrayfun(@(x) ['sln_symphony.', x.name(1:end-2)],k,'uni',0);
              matches = setdiff(matches, tables(matching));
                if numel(k)>1
                    warning('Possible table match: %s',matches{:});
                else
                    if ~strcmp(getenv('skip'), 'T')
                        answer = input(sprintf('Mismatch for table %s. Make new version? [y|n] ', protocol_name), 's');
                        if strcmp(answer,'y')
                            edit(fullfile(loc, k.name));
                            edit(fullfile(loc, sprintf('%sep',k.name(1:end-4))));
                        end
                    end
                end
          end
          % there are no matches at all
          if nnz(matching)
            [~,versions,~] = regexp(tables(matching), 'V([0-9]+)Block','match','tokens');
            versions = cellfun(@(x) str2double(x{1}{1}), versions);
            if isempty(versions)
                version = 1;
            else
                version = max(versions) + 1; %get the max of all the versions, add 1
            end
          else
            version = 1;
          end
          self.createTables(protocol_name, num2str(version), block_params, epoch_params);
          % and we will return false
        warning(bt.state,'backtrace');
        end


        function createTables(self,protocol_name, version, block_params, epoch_params)
            %w = {'Block', 'Epoch'};
            w = {'b', 'e'};
            w_full = {'block', 'epoch'};
            h = {'EpochBlock','Epoch'};

            p = {block_params, epoch_params};
            for n=1:2
                file_name = fullfile(...
                    fileparts(which(class(self))),...
                    ['ExperimentProt',protocol_name,'V',version,w{n},'p.m']...
                    );
                f = fopen(file_name,'w');
                fprintf(f,'%%{\n');
                fprintf(f,'#%s parameters for %s (%s) \n',w{n}, protocol_name, version);
                fprintf(f,'-> sln_symphony.Experiment%s\n', h{n});
                fprintf(f,'---\n');

                % fn = fieldnames(rmfield(p{n}, {'file_name','source_id','epoch_group_id','epoch_block_id'}));
                fn = setdiff(fieldnames(p{n}), {'file_name','source_id','epoch_group_id','epoch_block_id','epoch_id'});
                for i=1:numel(fn)
                    if all(arrayfun(@(x) isa(x.(fn{i}),'char'), p{n}))
                        if all(arrayfun(@(x) strcmp(x.(fn{i}),'T'), p{n}) | arrayfun(@(x) strcmp(x.(fn{i}),'F'), p{n}))
                            fprintf(f,'%s : enum(''F'',''T'') #bool\n', fn{i});
                        else 
                            fprintf(f,'%s : varchar(64)\n', fn{i});
                        end
                    elseif all(arrayfun(@(x) numel(x.(fn{i})) == 1, p{n}))
                        if contains(fn{i},'number')
                            fprintf(f,'%s : smallint unsigned\n', fn{i});
                        else
                            fprintf(f,'%s : float\n', fn{i});
                        end
                    else
                        fprintf(f,'%s : tinyblob\n', fn{i});
                    end
                end
                fprintf(f,'%%}\n');
                fprintf(f,'classdef ExperimentProt%sV%s%sp < sln_symphony.ExperimentProtocol\n',protocol_name, version, w{n});
                fprintf(f,'\tproperties\n');
                fprintf(f,'\n\t\t%%attributes to be renamed\n');
                fprintf(f,'\t\trenamed_attributes = struct();\n');
                fprintf(f,'\n\t\t%%attributes to be removed from the key\n');
                fprintf(f,'\t\tdropped_attributes = {};\n');
                % fprintf(f,'\n\t\t%%attributes to be transferred from the epoch key to the block key\n');
                % fprintf(f,'\t\ttransferred_attributes = {};\n');
                fprintf(f,'\tend\n');
                fprintf(f,'\tmethods\n');
                fprintf(f,'\t\tfunction %s_key = add_attributes(self, block_key, epoch_key) %%#ok<INUSL,INUSD>\n',lower(w_full{n}));
                fprintf(f,'\t\t%%add entities to the key based on others\n');
                fprintf(f,'\t\tend\n');
                fprintf(f,'\tend\n');
                fprintf(f,'end\n');
                fclose(f);
                edit(file_name);
            end

        end

        function parseProjectorSettings(self)
            i = arrayfun(@(x) isfield(x.parameters,'NDF'), self.key.epoch_blocks);
            k = arrayfun(@parseProjectorSetting, self.key.epoch_blocks(i));
            self.key.projector = [k(:).projector];
            self.key.LEDs = horzcat(k(:).LEDs)';
        end
        
        function removeRedundantFields(self)
            
            %remove fields that are either already in the keys or calculable from these
            i = arrayfun(@(x) isfield(x.parameters,'NDF'), self.key.epoch_blocks);
            self.key.block_params = arrayfun(@(x) removeRedundantBlockFields(x.parameters), self.key.epoch_blocks,'uni',0);
            self.key.block_params(i) = cellfun(@removeRedundantStageBlockFields, self.key.block_params(i),'uni',0);
            self.key.block_params = arrayfun(@(x) fixNulls(x.parameters), self.key.epoch_blocks,'uni',0);
            self.key.block_params(i) = cellfun(@fixNulls, self.key.block_params(i),'uni',0);
            
            i = arrayfun(@(x) isfield(x.parameters,'micronsPerPixel'), self.key.epochs);
            self.key.epoch_params = arrayfun(@(x) removeRedundantEpochFields(x.parameters), self.key.epochs,'uni',0);
            self.key.epoch_params(i) = cellfun(@removeRedundantStageEpochFields, self.key.epoch_params(i),'uni',0);
            
            i = cellfun(@(x) isfield(x, 'wholeCellRecordingMode_Ch1'), self.key.epoch_params);
            self.key.epoch_params(i) = cellfun(@(x) rmfield(x,'wholeCellRecordingMode_Ch1'), self.key.epoch_params(i),'uni',0);
            
            i = cellfun(@(x) isfield(x, 'wholeCellRecordingMode_Ch2'), self.key.epoch_params);
            self.key.epoch_params(i) = cellfun(@(x) rmfield(x,'wholeCellRecordingMode_Ch2'), self.key.epoch_params(i),'uni',0);

            self.key.epoch_blocks = arrayfun(@(x) rmfield(x,'parameters'), self.key.epoch_blocks);
            self.key.epochs = arrayfun(@(x) rmfield(x,'parameters'), self.key.epochs);
        end

        function copyPrimaryKeys(self)
          self.key.block_params = arrayfun(@(x,y) copyBlockPrimaryKey(x{1},y), self.key.block_params, self.key.epoch_blocks,'uni',0);
          self.key.epoch_params = arrayfun(@(x,y) copyEpochPrimaryKey(x{1},y), self.key.epoch_params, self.key.epochs,'uni',0);
        end

        function makeSnakeCase(self)
            self.key.block_params = cellfun(@toSnake,self.key.block_params,'uni',0);
            self.key.epoch_params = cellfun(@toSnake,self.key.epoch_params,'uni',0);
        end

        function convertToBool(self)
            self.key.block_params = cellfun(@(x) toBool(x,self.bool_types),self.key.block_params,'uni',0);
            self.key.epoch_params = cellfun(@(x) toBool(x,self.bool_types),self.key.epoch_params,'uni',0);
        end
    end
end

function outKey = parseProjectorSetting(inKey)

fn = fieldnames(inKey.parameters);

if ~contains(fn,'bitDepth') %if not bitDepth found, assume it is 8 bit
    inKey.parameters.bitDepth = 8;
end

if ~contains(fn,'frameRate') %if not frameRate found, assume it is 60 Hz
    inKey.parameters.frameRate = 60;
end

%of course, there are more projector parameters than these
%but these are the only ones that are consistent at an epoch block level
outKey.projector = struct(...
    'ndf', inKey.parameters.NDF,'bit_depth', inKey.parameters.bitDepth,...
    'frame_rate', inKey.parameters.frameRate,...
    'offset_x', inKey.parameters.offsetX,'offset_y',inKey.parameters.offsetY,...
    'file_name', inKey.file_name, 'source_id', inKey.source_id,...
    'epoch_group_id', inKey.epoch_group_id, 'epoch_block_id', inKey.epoch_block_id);

outKey.LEDs = struct('color', {},'value', {},...
    'file_name', {}, 'source_id', {},...
    'epoch_group_id', {}, 'epoch_block_id', {});

for i=1:numel(fn)
    if endsWith(fn{i},'LED')
        color = strsplit(fn{i},'LED');
        %Why missing colorPatterns sometimes?
        if isfield(inKey.parameters, 'colorPattern1')
            if isfield(inKey.parameters, 'colorPattern3')
                test = any(strcmp({inKey.parameters.colorPattern1, inKey.parameters.colorPattern2, inKey.parameters.colorPattern3},color{1}));
            else
                test = any(strcmp({inKey.parameters.colorPattern1, inKey.parameters.colorPattern2},color{1}));
            end
            if test
                outKey.LEDs(end+1).color = color{1};
                outKey.LEDs(end).value = inKey.parameters.(fn{i});
                outKey.LEDs(end).file_name = inKey.file_name;
                outKey.LEDs(end).source_id = inKey.source_id;
                outKey.LEDs(end).epoch_group_id = inKey.epoch_group_id;
                outKey.LEDs(end).epoch_block_id = inKey.epoch_block_id;
            end
        end
    end
end
end

function outKey = removeRedundantStageBlockFields(inKey)
outKey = rmFieldIfPresent(inKey, {...
    'NDF','RstarIntensity1','MstarIntensity1','SstarIntensity1',...    
    'RstarIntensity', ...
    'RstarIntensity2','MstarIntensity2','SstarIntensity2',...
    'MstarMean','SstarMean',... %TODO: Rstar also?
    'blueLED','greenLED','uvLED','bluePWM','greenPWM','uvPWM'...
    'redLED', 'red_led', ...
    'colorPattern1','colorPattern2','colorPattern3','numberOfPatterns',...
    'forcePrerender','prerender',...
    'frameRate','bitDepth',...
    'patternRate',...    
    'offsetX','offsetY'...
    });
end

function outKey = fixNulls(inKey)
    outKey = inKey;
    if isfield(inKey,'RstarMean')
        if ~isnumeric(inKey.RstarMean)
            outKey.RstarMean = nan;
        end
    end
    if isfield(inKey,'singleAngle')
        if ~isnumeric(inKey.singleAngle)
            outKey.singleAngle = -1;
        end
    end
end

function outKey = removeRedundantBlockFields(inKey)
outKey = rmFieldIfPresent(inKey, {...
    'chan1','chan1Hold','chan1Mode',...
    'chan2','chan2Hold','chan2Mode',...
    'chan3','chan3Hold','chan3Mode',...
    'chan4','chan4Hold','chan4Mode',...
    'pattern_rate', ...
    'sampleRate',...
    'scanHeadTrigger','stimTimeRecord'...
    'spikeDetectorMode','spikeThreshold', 'spikeThresholdVoltage', ...
    'doPWM','imaging',...
    });
end

function outKey = removeRedundantEpochFields(inKey)
if ~isfield(inKey, 'protocolVersion')
    inKey.protocolVersion = 0.9;
end
outKey = rmFieldIfPresent(inKey, {...
    'symphonyVersion'
    });
end

function outKey = removeRedundantStageEpochFields(inKey)
outKey = rmFieldIfPresent(inKey, {...
    'micronsPerPixel','angleOffsetFromRig'...
    });
end

function outKey = copyBlockPrimaryKey(outKey, inKey)
  outKey.file_name = inKey.file_name;
  outKey.source_id = inKey.source_id;
  outKey.epoch_group_id = inKey.epoch_group_id;
  outKey.epoch_block_id = inKey.epoch_block_id;
end

function outKey = copyEpochPrimaryKey(outKey, inKey)
  outKey.file_name = inKey.file_name;
  outKey.source_id = inKey.source_id;
  outKey.epoch_group_id = inKey.epoch_group_id;
  outKey.epoch_block_id = inKey.epoch_block_id;
  outKey.epoch_id = inKey.epoch_id;
end

function outKey = toSnake(inKey)
    fn = cellfun(@(x)changeCase(x,'snake'), fieldnames(inKey),'uni',0);
    outKey = cell2struct(struct2cell(inKey), fn, numel(inKey));
end

function key = toBool(key,shouldBeBool)
    fn = fieldnames(key);
    change = ismember(fn, shouldBeBool);
    if nnz(change) == 0
        return
    end

    for f=fn(change)'
        t = {key(:).(char(f))};
        i = cellfun(@logical, t);
        [t{i}] = deal('T');
        [t{~i}] = deal('F');
        [key(:).(char(f))]  = t{:};
    end


end

function key = joinKeys(keys)
% input is a cell array of structs
% output is a struct array
% missing fields in any struct are replaced with NaN
fields = cellfun(@fieldnames, keys, 'uni', 0);
if isempty(fields)
    key = struct();
    return;
end
uniqueFields = unique(vertcat(fields{:}));
emp = num2cell(nan(numel(uniqueFields), numel(keys)));
key = cell2struct(emp, uniqueFields, 1);
for n=1:numel(keys)
    for m=1:numel(fields{n})
        key(n).(fields{n}{m}) = keys{n}.(fields{n}{m});
    end
end
end

function key = rmFieldIfPresent(key, fields)
rm = intersect(fieldnames(key), fields);
key = rmfield(key, rm);
end
