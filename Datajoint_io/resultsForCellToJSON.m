function [] = resultsForCellToJSON(cellname)
resultsSchema = sln_results.getSchema;
resultsClasses = resultsSchema.classNames;

for i=1:length(resultsClasses)
    curName = resultsClasses{i};
    if ~contains(curName,'Runner')
        q = eval(sprintf('%s * sln_cell.CellName & ''cell_name="%s"''',curName,cellname));

        if q.exists
            json_filename = sprintf('%s_%s.json',cellname,extractAfter(curName,'sln_results.'))
            result_table = sln_results.toMatlabTable(q);

            %HACK to resample to 2KHz for things named with "trace"
            vnames = result_table.Properties.VariableNames;
            trace_vars = vnames(contains(vnames,'trace'));
            if ~isempty(trace_vars)
                for j=1:height(result_table)
                    sample_rate = result_table.sample_rate(j);
                    for v=1:length(trace_vars)
                        if isstruct(result_table{j, trace_vars{v}})
                            temp_struct = result_table{j, trace_vars{v}};
                            fields = fieldnames(temp_struct);
                            for f=1:length(fields)
                                temp_struct.(fields{f}) = resample(temp_struct.(fields{f}), 2000, sample_rate,'dimension',2);
                            end
                            result_table{j, trace_vars{v}} = temp_struct;
                        else
                            result_table{j, trace_vars{v}} = {resample(cell2mat(result_table{j, trace_vars{v}}),2000,sample_rate,'dimension',2)};
                        end
                    end
                    result_table{j, 'sample_rate'} = 2000;
                end
            end

            txt = jsonencode(result_table);
            if ~isfolder(cellname)
                mkdir(cellname);
            end
            fid = fopen([cellname filesep json_filename],'w');
            fprintf(fid,'%s',txt);
            fclose(fid);
            fprintf('Wrote %s\n',json_filename);
        end
    end

end

