%This is not a DJ table but is instead a wrapper for tables derived from a common analysis function
%Should this actually be a simple DJ manual table with a list of table names? Otherwise where is it stored? Does anything have to bee stored or is this just a set of functions? 
%Should it be an abstract class?
classdef ComputedResult %handle?
    properties
       %func_name - should it be a property? 
    end
    
    methods
        function [T, table_names] = getResult(func_name, varargin)
            %This function should parse the following inputs:
                % 'latest' last entry time
                % 'fromPipeline', pipeline_name
                % 'fromUser', user_name
                % 'all', everything in DB
                % 'withGitHash', git_hash_val
                % 'withParams', param_struct (will test using DataHash)
           
             %Returns a dj table T. If there were multiple tables matching the search, this is a joined table?
             %Thus, user can result the result with something like & 'cell_id="this_cell_number"'
             %optinally returns the list of table names involved in this query. This is important because they need to go into 
             %the new table header in the setResult call
        end
        
        function status = setResult(func_name, varargin)
            %This function builds a table if there is not one already matching this query.
            %It should parse the following inputs:
                % 'inPipeline', pipeline_name: adds pipeline_name to computed result
                % 'forUser', user_name: (defaults to current user), adds user_name to result
                % 'withParams', param_struct: analysis parameters to use (defaults to empty)
                % 'addToServerAuto': flag about whether to add this to the auto_populate script on the server (default to true?)
            
            %first run getResult(func_name, withParams) to see if the result exists for another user/pipeline 
            %and ask if you want to copy it instead of recomputing 
            
            %make new result table with the correct specifications
            %populate it and report on the progress
            
            %IMPORTANT: part of the tricky part here is getting the dependencies correct. The parser in here needs to look for 
            %getResult calls in func_name and add them as dependencies in the table
            
            %add the newly created table to the table list for this func_name with an auto-incrementer for the version numbers 
            
        end
        
        function status = purgeResult(funcName, varargin)
            %delete results, for example when there was a bug in the code
            %This should work similarly to getResults with some of the same input parsing.
            %Critical here is the gitHash. Perhaps we shuold require that it be specified?
            
        end
        
        
        
%         function obj = ComputedResult(pipeline_name, analysis_params)
%             if nargin<2
%                 analysis_params = struct;
%             end
%             if nargin<1
%                 pipeline_name = 'scratch';
%             end
%             obj.pipeline_name = pipeline_name;
%             obj.analysis_params = analysis_params;
%             curDir = pwd;
%             cd(getenv('DJ_ROOT'));
%             [err, hash] = system('git describe --always');
%             cd(curDir);
%             if ~err
%                 obj.git_hash = deblank(hash);                
%             else
%                 obj.git_hash = [];
%                 disp('git error: result not inserted');
%             end        
%             try
%                 C = dj.conn;
%                 obj.user_name = C.user;
%             catch
%                 disp('DJ connection error: result not inserted');
%                 obj.user_name = [];
%             end
%         end        
    end
    
end

% 
% git_hash
%         pipeline_name
%         analysis_params
%         user_name     