%{ NOT a datajoint table


%}
classdef ExperimentProtocols < handle

    properties
        key
        bool_types = {'logScaling', 'randomOrdering', 'alternatePatterns'};
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

                  success = self.insertProtocol(changeCase(protocols{i},'upperCamel'), vertcat(b{:}), vertcat(e{:})) && success;
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
          tables = sln_symphony.getSchema().classNames;
          matching = startsWith(tables, ['sln_symphony.ExperimentProtocol', protocol_name])...
              & endsWith(tables, 'BlockParameters');
          success = false;
          emptyMatches = {};
          for match = tables(matching)

              b = feval(char(match));% <- gets an object of the class
              e = feval([match{1}(1:end-15), 'EpochParameters']);
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
          %%we failed to insert
          if ~isempty(emptyMatches)
              %we probably mean to edit one of these
              if numel(emptyMatches) > 1
                  warning('Possible table match: %s',emptyMatches{:});
              else
                  edit(char(emptyMatches));
                  edit(sprintf('%sEpochParameters',emptyMatches{1}(1:end-15)));
              end
              return
          end
          loc = fileparts(which(class(self)));
          k = dir(fullfile(loc, ['ExperimentProtocol', protocol_name ,'*BlockParameters.m']));
          if ~isempty(k)
              matches = arrayfun(@(x) ['sln_symphony.', x.name(1:end-2)],k,'uni',0);
              matches = setdiff(matches, tables(matching));
                if numel(k)>1
                    warning('Possible table match: %s',matches{:});
                else
                    edit(fullfile(loc, k.name));
                    edit(fullfile(loc, sprintf('%sEpochParameters',k.name(1:end-17))));
                end
          end
          % there are no matches at all
          if ~nnz(matching)
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

        end

        function createTables(self,protocol_name, version, block_params, epoch_params)
            w = {'Block', 'Epoch'};
            h = {'EpochBlock','Epoch'};
            p = {block_params, epoch_params};
            for n=1:2
                file_name = fullfile(...
                    fileparts(which(class(self))),...
                    ['ExperimentProtocol',protocol_name,'V',version,w{n},'Parameters.m']...
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
                fprintf(f,'classdef ExperimentProtocol%sV%s%sParameters < sln_symphony.ExperimentProtocol\n',protocol_name, version, w{n});
                fprintf(f,'\tproperties\n');
                fprintf(f,'\n\t\t%%attributes to be renamed\n');
                fprintf(f,'\t\trenamed_attributes = struct();\n');
                fprintf(f,'\n\t\t%%attributes to be removed from the key\n');
                fprintf(f,'\t\tdropped_attributes = {};\n');
                % fprintf(f,'\n\t\t%%attributes to be transferred from the epoch key to the block key\n');
                % fprintf(f,'\t\ttransferred_attributes = {};\n');
                fprintf(f,'\tend\n');
                fprintf(f,'\tmethods\n');
                fprintf(f,'\t\tfunction %s_key = add_attributes(self, block_key, epoch_key) %%#ok<INUSL,INUSD>\n',lower(w{n}));
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
            self.key.LEDs = vertcat(k(:).LEDs);
        end
        
        function removeRedundantFields(self)
            
            %remove fields that are either already in the keys or calculable from these
            i = arrayfun(@(x) isfield(x.parameters,'NDF'), self.key.epoch_blocks);
            self.key.block_params = arrayfun(@(x) removeRedundantBlockFields(x.parameters), self.key.epoch_blocks,'uni',0);
            self.key.block_params(i) = cellfun(@removeRedundantStageBlockFields, self.key.block_params(i),'uni',0);
            
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
        if any(strcmp({inKey.parameters.colorPattern1, inKey.parameters.colorPattern2, inKey.parameters.colorPattern3},color{1}))
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

function outKey = removeRedundantStageBlockFields(inKey)
outKey = rmfield(inKey, {...
    'NDF','RstarIntensity1','MstarIntensity1','SstarIntensity1',...
    'blueLED','greenLED','uvLED'...
    'colorPattern1','colorPattern2','colorPattern3','numberOfPatterns',...
    'forcePrerender','prerender',...
    'frameRate','bitDepth',...
    'offsetX','offsetY'...
    });
end

function outKey = removeRedundantBlockFields(inKey)
outKey = rmfield(inKey, {...
    'chan1','chan1Hold','chan1Mode',...
    'chan2','chan2Hold','chan2Mode',...
    'sampleRate',...
    'scanHeadTrigger','stimTimeRecord'...
    'spikeDetectorMode','spikeThreshold'...
    });
end

function outKey = removeRedundantEpochFields(inKey)
outKey = rmfield(inKey, {...
    'symphonyVersion'
    });
end

function outKey = removeRedundantStageEpochFields(inKey)
outKey = rmfield(inKey, {...
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