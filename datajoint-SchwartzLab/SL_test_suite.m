classdef SL_test_suite < matlab.unittest.TestCase

    properties
        schema = sl_test.getSchema()
        results = containers.Map();
    end

    methods (TestClassSetup)

        function setupDB(testCase)
            import dj.*;
            %drop all the root tables and then re-create them

            tables = testCase.schema.classNames;

            dj.set('suppressPrompt',true);

            for table = tables
                t = feval(table{1});
                if length(t.ancestors) == 1
                    drop(t);
                end

            end

        end

    end

    methods (TestClassTeardown)

        function teardownDB(testCase)
            dj.set('suppressPrompt',false);
        end

    end

    methods (TestMethodSetup)

        function setupTables(testCase)
            %delete all the entries from all the root tables
            %this is important to make sure that tests don't depend on each other
            
            tables = testCase.schema.classNames;
            for table = tables
                del(feval(table{1}));
            end

        end

    end

    methods (Test)
        %the actual test functions go here
        %tests should be independent from each other
        %can use generateEntries to populate dependency tables

        function makeNAnimals(testCase)
            testCase.generateEntries(sl_test.Animal, 10); %populate sl_test.Animal with 10 mice

            q = fetch(sl_test.Animal, '*'); %query the DB
          
            testCase.results('makeNAnimals') = q;
            testCase.verifyEqual(length(q), 10, 'Did not generate expected number of mice');
        end
        
        function killNAnimals(testCase)
            testCase.generateEntries(sl_test.Animal, 10);
            testCase.generateEntries(sl_test.AnimalEvent, 50);
            testCase.generateEntries(sl_test.AnimalEventDeceased, 5);

            q = sl_test.Animal.living();

            testCase.results('killNAnimals') = q;
            testCase.verifyEqual(length(q), 5, 'Did not generate expected number of mice');

        end

        % function makeAnimalPartTables(testCase)
             
%             testCase.generateEntries(sl_test.AnimalLive, 5); %populate sl_test.AnimalLive with 5 mice
%             testCase.generateEntries(sl_test.AnimalForBehavior, 5); %populate sl_test.AnimalForBehavior with 5 mice
%             testCase.generateEntries(sl_test.AnimalForExperimentalInjection, 5); %populate sl_test.AnimalForBehavior with 5 mice
            
%             q = fetch(sl_test.AnimalLive, '*');
%             testCase.results('makeAnimalPartTables') = q;
         
% %             behAnimals = sl_test.Animal & sl_test.AnimalForBehavior;
% %             injAnimals = sl_test.Animal & sl_test.AnimalForExperimentalInjection;
            
%             testCase.verifyEqual(length(q), 5, 'Did not generate expected number of live mice');
            %testCase.verifyEqual(length(behAnimals), 5, 'Did not generate expected number of beh mice');
            %testCase.verifyEqual(length(injAnimals), 5, 'Did not generate expected number of inj mice');
            
            
        % end

    end

    methods

        function generateEntries(testCase, table, N)
            fN = 20*N; %make extra entries and then delete them, to ensure primary key uniqueness.... 
            tables = testCase.schema.tableNames;
            %create random entries in the input table and any tables it
            %depends on

            if isa(table, 'char')%table.parents (below) returns a string with the table name, not the actual table
                table = feval(table); %get the table object from the table name
            end

%             tableName = regexp(table.plainTableName, '(\w+)', 'match');
%             tableName{1}(1) = upper(tableName{1}(1));

            if length(fetch(table)) > 0
                return%no need to add to this table
            end

            tableFns = tables.keys();
            for i = table.parents
                p = regexp(i{1}, '.+\.`(?<key>.+)`', 'names');
                testCase.generateEntries(tableFns{cellfun(@(x) strcmp(x,p.key), tables.values())}, 3); %make 3 random entries into the parent table
            end

            %create an empty structure with fields matching the table
            k = table.tableHeader.attributes;
            c = cell(length(k), fN);
            s = cell2struct(c, {k(:).name});

            p = strsplit(table.className, '.');
            fk = testCase.schema.conn.foreignKeys;
            thisFK = fk(strcmp({fk.from}, sprintf('`%s`.`%s`',p{1},table.plainTableName))); %sprintf('`%s`.`%s`', p{1}, p{2})

            for i = 1:numel(thisFK)
                q = regexp(thisFK(i).ref, '.+\.`(?<key>.+)`', 'names'); %get the referred table name
%                 q.key(1) = upper(q.key(1));
                ref_attrs = cell(size(thisFK(i).ref_attrs));
                [ref_attrs{:}] = fetchn(feval(tableFns{cellfun(@(x) strcmp(x,q.key), tables.values())}), thisFK(i).ref_attrs{:}); %fetch entries by the referred attribute
                double_attrs = cellfun(@(x) isa(x,'double'), ref_attrs);
                ref_attrs(double_attrs) = cellfun(@(x) num2cell(x), ref_attrs(double_attrs),'uniformoutput',false);
                ref_attrs = horzcat(ref_attrs{:});
                
                ref_attrs = ref_attrs(randi(length(ref_attrs), 1, fN),:); %randomly select dependent entries

%                 if isa(ref_attrs,'double')
%                    ref_attrs = num2cell(ref_attrs);
%                 end
                for j = 1:size(ref_attrs,2)
                    [s.(thisFK(i).attrs{j})] = ref_attrs{:,j};
                end
            end

            %fill the table with values...
            for i = 1:numel(k)

                if isempty(s(1).(k(i).name)) &&~k(i).isautoincrement

                    if k(i).isNumeric
                        attrs = num2cell(randi(256, 1, fN)-1); %random tiny int

                    elseif contains(k(i).type, 'enum')
                        attrs = regexp(k(i).type, '([\w\s]+)', 'match');
                        attrs = attrs(2:end); %drop the 'enum'
                        attrs = attrs(randi(length(attrs), 1, fN)); %random selection of values in enum list

                    elseif strcmp(k(i).type, 'date')
                        attrs = cellstr(datestr(3650 * rand(1, fN) + datenum('2010-01-01'), 'yyyy-mm-dd')); %random date in the 2010s
                    
                    elseif strcmp(k(i).type, 'datetime')
                        attrs = cellstr(datestr(datetime(floor([2010 01 01 00 00 00] + rand(fN,6).*[10 11 11 24 60 60])), 'yyyy-mm-dd HH:MM:SS')); %random date in the 2010s

                    elseif contains(k(i).type, 'blob')
                        attrs = cell(fN, 1); %empty

                    else %isString
                        attrs = cellstr(char(randi([33 126], fN, 10))); %N random strings of length 10

                    end

                    [s(:).(k(i).name)] = attrs{:};
                end

            end
            
            valid = false(fN, 1);

            if any([k(:).iskey] & [k(:).isautoincrement])
                %this table is guaranteed to have unique PKs by mySQL
%                 s = s(1:N);
                valid(1:fN) = true;
            else
                PKs = {k([k(:).iskey]).name};
                nPK = numel(PKs);
                c = zeros(fN, nPK);
                for i = 1:nPK
                    [~,~,c(:,i)] = unique(cell2mat({s(:).(PKs{i})}'),'rows');
                end
                
                [~,a,~] = unique(c, 'rows'); %get the entries with unique PKs
                valid(a) = true;
%                 s = s(a(1:N));
            end
            
            %parse unique constraints
            uKeys = testCase.schema.conn.query(sprintf('select distinct CONSTRAINT_NAME from information_schema.TABLE_CONSTRAINTS where table_name = "%s" and constraint_type = "UNIQUE"',table.plainTableName));
            if ~isempty(uKeys.CONSTRAINT_NAME)
                nUK = numel(uKeys.CONSTRAINT_NAME);
                c = zeros(fN, nUK);
                for i = 1:nUK
                    [~,~,c(:,i)] = unique(cell2mat({s(:).(uKeys.CONSTRAINT_NAME{i})}'),'rows');
                end
                [~,a2,~] = unique(c, 'rows');
                valid(setdiff(1:fN, a2)) = false;
            end
            
            s = s(valid);
            s = s(randperm(numel(s), N));
            
            %now that we've generated the fake data we can insert
            insert(table, s);
        end

    end

end
