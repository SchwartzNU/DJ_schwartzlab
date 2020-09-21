classdef SL_test_suite < matlab.unittest.TestCase

    properties
        results = containers.Map();
    end

    methods (TestClassSetup)

        function setupDB(testCase)
            import dj.*;
            %drop all the root tables and then re-create them

            tables = sl_test.getSchema().classNames;

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
            
            tables = sl_test.getSchema().classNames;
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
        
        function makeAnimalPartTables(testCase)
            testCase.generateEntries(sl_test.Animal, 10); 
            
            testCase.generateEntries(sl_test.AnimalLive, 5); %populate sl_test.AnimalLive with 5 mice
            testCase.generateEntries(sl_test.AnimalForBehavior, 5); %populate sl_test.AnimalForBehavior with 5 mice
            testCase.generateEntries(sl_test.AnimalForExperimentalInjection, 5); %populate sl_test.AnimalForBehavior with 5 mice
            
            q = fetch(sl_test.AnimalLive, '*');
            testCase.results('makeAnimalPartTables') = q;
         
%             behAnimals = sl_test.Animal & sl_test.AnimalForBehavior;
%             injAnimals = sl_test.Animal & sl_test.AnimalForExperimentalInjection;
            
            testCase.verifyEqual(length(q), 5, 'Did not generate expected number of live mice');
            %testCase.verifyEqual(length(behAnimals), 5, 'Did not generate expected number of beh mice');
            %testCase.verifyEqual(length(injAnimals), 5, 'Did not generate expected number of inj mice');
            
            
        end

    end

    methods

        function generateEntries(testCase, table, N)
            fN = 20*N; %make extra entries and then delete them, to ensure primary key uniqueness.... 
            
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

            for i = table.parents
                p = regexp(i{1}, '(\w+)', 'match');
                p{2}(1) = upper(p{2}(1));
                testCase.generateEntries(sprintf('%s.%s', p{1}, p{2}), 3); %make 3 random entries into the parent table
            end

            %create an empty structure with fields matching the table
            k = table.tableHeader.attributes;
            c = cell(length(k), fN);
            s = cell2struct(c, {k(:).name});

            p = strsplit(table.className, '.');
            fk = table.schema.conn.foreignKeys;
            thisFK = fk(strcmp({fk.from}, sprintf('`%s`.`%s`',p{1},table.plainTableName))); %sprintf('`%s`.`%s`', p{1}, p{2})

            for i = 1:numel(thisFK)
                q = regexp(thisFK(i).ref, '`\W?(?<key>\w+)`$', 'names'); %get the referred table name
                q.key(1) = upper(q.key(1));
                ref_attrs = fetchn(sl_test.(q.key), thisFK(i).ref_attrs{:}); %fetch entries by the referred attribute
                ref_attrs = ref_attrs(randi(length(ref_attrs), 1, fN)); %randomly select dependent entries

                if isa(ref_attrs,'double')
                   ref_attrs = num2cell(ref_attrs);
                end
                
                [s.(thisFK(i).attrs{:})] = ref_attrs{:};
            end

            %fill the table with values...
            for i = 1:numel(k)

                if isempty(s(1).(k(i).name)) &&~k(i).isautoincrement

                    if k(i).isNumeric
                        attrs = num2cell(randi(256, 1, fN)-1); %random tiny int

                    elseif contains(k(i).type, 'enum')
                        attrs = regexp(k(i).type, '(\w+)', 'match');
                        attrs = attrs(2:end); %drop the 'enum'
                        attrs = attrs(randi(length(attrs), 1, fN)); %random selection of values in enum list

                    elseif strcmp(k(i).type, 'date')
                        attrs = cellstr(datestr(3650 * rand(1, fN) + datenum('2010-01-01'), 'yyyy-mm-dd')); %random date in the 2010s

                    elseif contains(k(i).type, 'blob')
                        attrs = cell(fN, 1); %empty

                    else %isString
                        attrs = cellstr(char(randi([33 126], fN, 10))); %N random strings of length 10

                    end

                    [s(:).(k(i).name)] = attrs{:};
                end

            end

            if any([k(:).iskey] & [k(:).isautoincrement])
                %this table is guaranteed to have unique PKs by mySQL
                s = s(1:N);
            else
                [~,a,c] = unique(cell2mat({s(:).([k([k(:).iskey]).name])}'), 'rows'); %get the entries with unique PKs
                s = s(a(1:N));
            end
            
         
            %now that we've generated the fake data we can insert
            insert(table, s);
        end

    end

end
