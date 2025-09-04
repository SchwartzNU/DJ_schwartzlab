classdef Query2Table < matlab.apps.AppBase
    % Query2Table(q): pick numeric columns from a DataJoint query and preview/fetch as table.

    properties (Access = public)
        UIFigure matlab.ui.Figure
    end

    properties (Access = private)
        Query
        NumericAttrNames cell = {}
        BlobAttrNames cell = {}

        RootGrid        matlab.ui.container.GridLayout
        ControlGrid     matlab.ui.container.GridLayout
        SelectorScroll  matlab.ui.container.GridLayout   % <-- fixed type
        PreviewTable    matlab.ui.control.Table

        AddBtn   matlab.ui.control.Button
        RemoveBtn matlab.ui.control.Button
        FetchBtn matlab.ui.control.Button
        ExportBtn matlab.ui.control.Button
        ExportFormatDropDown matlab.ui.control.DropDown
        ShowTableCheckBox matlab.ui.control.CheckBox
        RowsLabel matlab.ui.control.Label
        RowsSpinner matlab.ui.control.Spinner
        MaxPreviewRows double = 10
        SaveBtn matlab.ui.control.Button
        LoadBtn matlab.ui.control.Button

        Selectors matlab.ui.control.DropDown = matlab.ui.control.DropDown.empty
        AggSelectors matlab.ui.control.DropDown = matlab.ui.control.DropDown.empty
        CustomAggFns cell = {}
        CustomAggText cell = {}
        AggLibraryNames cell = {}
        AggLibMap containers.Map = containers.Map('KeyType','char','ValueType','any')
        UnitEditors matlab.ui.control.EditField = matlab.ui.control.EditField.empty
        CurrentTable table = table()
        LastStruct struct = struct([])
        Debug logical = false
        DebugMaxRows double = 5
    end

    methods (Access = public)
        function app = Query2Table(q)
            if nargin < 1, q = []; end
            app.Query = q;
            % Initialize debug from env var Q2T_DEBUG
            try
                dbg = getenv('Q2T_DEBUG');
                app.Debug = ~isempty(dbg) && any(strcmpi(strtrim(dbg), {'1','true','on'}));
            catch
            end

            % Get attribute names
            try
                if ~isempty(q)
                    names = q.header.notBlobs;
                    blobs = q.header.blobNames;
                    if isstring(names), names = cellstr(names); end
                    if isstring(blobs), blobs = cellstr(blobs); end
                    app.BlobAttrNames = blobs(:).';
                    allnames = [names(:); blobs(:)].';
                    app.NumericAttrNames = allnames; % reuse field for dropdown items
                end
            catch ME
                warning('Could not read q.header fields: %s', ME.message);
            end

            createUI(app);
            loadReducerLibrary(app);
            % Start with no columns; user adds manually
            onSelectionChanged(app);

            refreshPreview(app);
            registerApp(app, app.UIFigure);
        end
    end

    methods (Access = private)
        function pk = primaryKeyNames(app)
            % Try to obtain primary key attribute names from DataJoint header
            pk = {};
            try
                h = app.Query.header;
                % Common possibilities for MATLAB DataJoint
                if isstruct(h)
                    if isfield(h,'primaryKey')
                        pk = h.primaryKey;
                    elseif isfield(h,'primaryKeyNames')
                        pk = h.primaryKeyNames;
                    elseif isfield(h,'primary_key')
                        pk = h.primary_key;
                    end
                else
                    % handle object with properties
                    if isprop(h,'primaryKey')
                        pk = h.primaryKey;
                    elseif isprop(h,'primaryKeyNames')
                        pk = h.primaryKeyNames;
                    elseif isprop(h,'primary_key')
                        pk = h.primary_key;
                    end
                end
                if isstring(pk), pk = cellstr(pk); end
                if ~iscell(pk), pk = {}; end
            catch
                pk = {};
            end
        end
        function createUI(app)
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                app.UIFigure = uifigure('Name','Query → Table','Position',[100 100 1400 640]);
            end

            app.RootGrid = uigridlayout(app.UIFigure,[1 2]);
            app.RootGrid.ColumnWidth = {520,'1x'};
            app.RootGrid.Padding = [12 12 12 12];
            app.RootGrid.ColumnSpacing = 12;

            app.ControlGrid = uigridlayout(app.RootGrid,[4 1]);
            app.ControlGrid.RowHeight = {40,28,30,'1x'};
            app.ControlGrid.Layout.Column = 1;

            % Top button bar
            btnRow = uigridlayout(app.ControlGrid,[1 5]);
            btnRow.ColumnWidth = {'fit','fit','fit','fit','fit'};
            btnRow.ColumnSpacing = 8;
            btnRow.Padding = [0 0 0 0];
            btnRow.Layout.Row = 1;

            app.AddBtn    = uibutton(btnRow,'Text','+ Add column', ...
                'ButtonPushedFcn',@(~,~)addSelector(app));
            app.RemoveBtn = uibutton(btnRow,'Text','- Remove last', ...
                'ButtonPushedFcn',@(~,~)removeLastSelector(app));
            app.FetchBtn  = uibutton(btnRow,'Text','Fetch preview', ...
                'ButtonPushedFcn',@(~,~)refreshPreview(app,true));
            app.ExportBtn = uibutton(btnRow,'Text','Export…', ...
                'ButtonPushedFcn',@(~,~)exportData(app));
            app.ExportFormatDropDown = uidropdown(btnRow, ...
                'Items', {'MAT-Table','MAT-Struct','CSV','HDF5'}, ...
                'Value', 'MAT-Table');
            
            % Options row: show/hide + rows spinner
            optsRow = uigridlayout(app.ControlGrid,[1 3]);
            optsRow.ColumnWidth = {'fit','fit','1x'};
            optsRow.ColumnSpacing = 8;
            optsRow.Padding = [0 0 0 0];
            optsRow.Layout.Row = 2;
            app.ShowTableCheckBox = uicheckbox(optsRow, ...
                'Text','Show table', 'Value', true, ...
                'ValueChangedFcn', @(~,~)updateTableView(app));
            app.RowsLabel = uilabel(optsRow,'Text','Rows:');
            app.RowsLabel.HorizontalAlignment = 'right';
            app.RowsSpinner = uispinner(optsRow,'Limits',[1 Inf],'Step',1,'Value',app.MaxPreviewRows, ...
                'ValueChangedFcn',@(~,~)onRowsChanged(app));

            % State row: Save / Load selection state
            stateRow = uigridlayout(app.ControlGrid,[1 3]);
            stateRow.ColumnWidth = {'1x','1x','1x'};
            stateRow.ColumnSpacing = 8;
            stateRow.Padding = [0 0 0 0];
            stateRow.Layout.Row = 3;
            app.SaveBtn = uibutton(stateRow,'Text','Save state…', ...
                'ButtonPushedFcn',@(~,~)saveStateToMat(app));
            app.LoadBtn = uibutton(stateRow,'Text','Load state…', ...
                'ButtonPushedFcn',@(~,~)loadStateFromMat(app));

            % Scrollable selector area (grid is scrollable in newer MATLAB)
            app.SelectorScroll = uigridlayout(app.ControlGrid,[1 1]);
            app.SelectorScroll.Scrollable  = 'on';
            app.SelectorScroll.Padding     = [0 0 0 0];
            app.SelectorScroll.RowHeight   = {'fit'};  % will expand dynamically
            app.SelectorScroll.ColumnWidth = {'1x'};
            app.SelectorScroll.RowSpacing  = 6;
            app.SelectorScroll.Layout.Row  = 4;

            app.PreviewTable = uitable(app.RootGrid,'Data',table());
            app.PreviewTable.Layout.Column = 2;
            app.PreviewTable.ColumnSortable = true;
        end

        function addSelector(app, presetName)
            if isempty(app.NumericAttrNames)
                uialert(app.UIFigure,'No attributes found in the query header.','No Columns'); return
            end
            row = uigridlayout(app.SelectorScroll,[1 4]);
            row.ColumnWidth = {70,'1x','fit',120};
            row.ColumnSpacing = 8;
            row.Padding = [0 0 0 0];
            % Place on a new row and grow parent rows
            newRowIdx = numel(app.Selectors) + 1;
            rh = app.SelectorScroll.RowHeight;
            if numel(rh) < newRowIdx
                app.SelectorScroll.RowHeight = [rh repmat({'fit'},1,newRowIdx-numel(rh))];
            end
            row.Layout.Row = newRowIdx;
            uilabel(row,'Text',sprintf('Column %d', numel(app.Selectors)+1), 'HorizontalAlignment','right');

            dd = uidropdown(row,'Items',app.NumericAttrNames, ...
                'ValueChangedFcn',@(src,~)onAttributeChanged(app, src));
            if nargin>1 && any(strcmp(presetName, app.NumericAttrNames))
                dd.Value = presetName;
            end
            app.Selectors = [app.Selectors dd];
            % Aggregation selector (visible only for blob attributes)
            aggdd = uidropdown(row,'Items',aggregationItems(app), 'Value','mean');
            aggdd.Visible = 'off';
            aggdd.Tooltip = 'Aggregation for non-scalar columns';
            aggdd.ValueChangedFcn = @(src,~)onAggChanged(app, src);
            app.AggSelectors = [app.AggSelectors aggdd];
            app.CustomAggFns{end+1} = []; %#ok<AGROW>
            app.CustomAggText{end+1} = ''; %#ok<AGROW>
            % Units edit field
            uedit = uieditfield(row,'text','Placeholder','units');
            uedit.Tooltip = 'Units (optional)';
            app.UnitEditors = [app.UnitEditors uedit];
            onSelectionChanged(app);
            layoutSelectors(app);
            onAttributeChanged(app, dd); % ensure correct agg visibility
        end

        function removeLastSelector(app)
            if isempty(app.Selectors), return; end
            last = app.Selectors(end);
            delete(ancestor(last,'matlab.ui.container.GridLayout')); % delete row grid
            app.Selectors(end) = [];
            if ~isempty(app.AggSelectors)
                app.AggSelectors(end) = [];
            end
            if ~isempty(app.CustomAggFns)
                app.CustomAggFns(end) = [];
            end
            if ~isempty(app.UnitEditors)
                app.UnitEditors(end) = [];
            end
            % shrink the selector grid row heights
            rh = app.SelectorScroll.RowHeight;
            if ~isempty(rh)
                app.SelectorScroll.RowHeight = rh(1:max(1,numel(rh)-1));
            end
            onSelectionChanged(app);
            layoutSelectors(app);
        end

        function names = selectedAttributeNames(app)
            if isempty(app.Selectors), names = {}; return; end
            names = arrayfun(@(d)d.Value, app.Selectors, 'UniformOutput', false);
            names = unique(names,'stable'); % keep order, drop duplicates
        end

        function onSelectionChanged(app)
            app.RemoveBtn.Enable = matlab.lang.OnOffSwitchState(~isempty(app.Selectors));
            % Auto-refresh a quick preview (limited rows) on selection change
            refreshPreview(app, true);
        end

        function onAttributeChanged(app, src)
            % Toggle aggregation dropdown visibility for blob attributes
            idx = find(app.Selectors == src, 1);
            if isempty(idx), return; end
            isBlob = any(strcmp(src.Value, app.BlobAttrNames));
            if idx <= numel(app.AggSelectors) && isvalid(app.AggSelectors(idx))
                app.AggSelectors(idx).Visible = matlab.lang.OnOffSwitchState(isBlob);
            end
            onSelectionChanged(app);
        end

        function onAggChanged(app, src)
            % Handle custom function choice
            idx = find(app.AggSelectors == src, 1);
            if isempty(idx), return; end
            if strcmp(src.Value,'custom…')
                % Open a file chooser rooted at reducer library folder
                startDir = app.reducerBaseFolder();
                if ~isfolder(startDir)
                    startDir = pwd;
                end
                [f, p] = uigetfile({'*.m','MATLAB Function (*.m)'}, ...
                                   'Select Custom Aggregation Function', startDir);
                if isequal(f,0), return; end
                try
                    % Add chosen folder to path (session-only)
                    addpath(p);
                catch
                end
                try
                    [~, name, ~] = fileparts(f);
                    fh = str2func(name);
                    % Do not execute user function here; just record handle.
                    % Arity will be adapted at runtime.
                    app.CustomAggFns{idx} = fh;
                    app.CustomAggText{idx} = name;
                catch ME
                    uialert(app.UIFigure, sprintf('Invalid function file:\n%s', ME.message), 'Custom Function Error');
                end
            end
            refreshPreview(app, true);
        end

        function layoutSelectors(app)
            % Ensure each selector row is placed on its own line and labeled
            n = numel(app.Selectors);
            if n==0, return; end
            app.SelectorScroll.RowHeight = repmat({'fit'},1,n);
            for i = 1:n
                dd = app.Selectors(i);
                row = ancestor(dd,'matlab.ui.container.GridLayout');
                if ~isempty(row) && isvalid(row)
                    row.Layout.Row = i;
                    % Update the label text in the same row
                    lbl = findobj(row,'Type','uilabel');
                    if ~isempty(lbl)
                        lbl(1).Text = sprintf('Column %d', i);
                        lbl(1).HorizontalAlignment = 'right';
                    end
                end
            end
        end

        function refreshPreview(app, limited)
            if nargin < 2, limited = true; end
            if isempty(app.Query)
                app.CurrentTable = table(); updateTableView(app); return
            end
            attrs = selectedAttributeNames(app);
            if isempty(attrs)
                app.CurrentTable = table(); updateTableView(app); return
            end
            try
                % Fast, limited fetch for preview
                pk = app.primaryKeyNames();
                % Build fetch list that includes primary keys for tuple support
                fetchAttrs = attrs;
                for i = 1:numel(pk)
                    if ~any(strcmp(fetchAttrs, pk{i})), fetchAttrs{end+1} = pk{i}; end %#ok<AGROW>
                end
                % If we couldn't detect PK names, request 'KEY' token so keys are included
                if isempty(pk)
                    fetchAttrs{end+1} = 'KEY'; %#ok<AGROW>
                end
                % Fast preview: try limited fetch, with fallback for blob payloads
                if limited
                    S = limitedFetchStruct(app, fetchAttrs, app.MaxPreviewRows);
                else
                    S = fetch(app.Query, fetchAttrs{:});
                end
                if isempty(S)
                    % Create an empty table with selected variable names so headers show
                    varTypes = repmat({'string'}, 1, numel(attrs));
                    T = table('Size',[0 numel(attrs)], ...
                        'VariableTypes',varTypes, 'VariableNames',attrs);
                else
                    T = struct2table(S);
                    % Stash full struct rows for custom aggregators (tuple support)
                    app.LastStruct = S;
                    % Reorder columns to match selection order
                    keep = intersect(attrs, T.Properties.VariableNames, 'stable');
                    T = T(:, keep);
                    % Apply aggregations for blob attributes
                    T = applyAggregations(app, T);
                end
                app.CurrentTable = T;
                updateTableView(app);
            catch ME
                uialert(app.UIFigure,sprintf('Fetch failed:\n%s',ME.message),'DataJoint Error');
            end
        end

        function S = limitedFetchStruct(app, attrs, n)
            % Try several ways to limit rows; ensure blob fields are populated.
            S = [];
            % Helper to verify blobs are present
            function ok = blobsPresent(SS)
                ok = ~isempty(SS);
                if ~ok, return; end
                try
                    % If any requested attr is a blob, ensure first row has data
                    for ii = 1:numel(attrs)
                        a = attrs{ii};
                        if any(strcmp(a, app.BlobAttrNames))
                            if ~isfield(SS, a) || isempty(SS(1).(a))
                                ok = false; return;
                            end
                        end
                    end
                catch
                    % if check fails, treat as not ok
                    ok = false;
                end
            end
            % Attempt 1: string form 'LIMIT n'
            try
                S = fetch(app.Query, attrs{:}, sprintf('LIMIT %d', n));
                if blobsPresent(S), return; end
            catch
            end
            % Attempt 2: key/value form
            try
                S = fetch(app.Query, attrs{:}, 'LIMIT', n);
                if blobsPresent(S), return; end
            catch
            end
            % Fallback: fetch all then slice, to guarantee blob payloads
            S = fetch(app.Query, attrs{:});
            if numel(S) > n, S = S(1:n); end
        end

        function T = applyAggregations(app, T)
            % For any selected attribute that is a blob, reduce to a scalar
            vn = T.Properties.VariableNames;
            visibleNames = vn; % used to strip non-key fields from tuple
            renameOld = {};
            renameNew = {};
            for k = 1:numel(vn)
                name = vn{k};
                if any(strcmp(name, app.BlobAttrNames))
                    % find first selector picking this name
                    idx = find(arrayfun(@(d)strcmp(d.Value,name), app.Selectors), 1, 'first');
                    fh = app.aggregatorForIndex(idx);
                    if ~isempty(fh)
                        col = T.(name);
                        out = nan(height(T),1);
                        for r = 1:height(T)
                            % Build tuple with only primary keys when known; else pass full row
                            tuple = struct();
                            try
                                if ~isempty(app.LastStruct)
                                    src = app.LastStruct(r);
                                    pkn = app.primaryKeyNames();
                                    if ~isempty(pkn)
                                        tuple = struct();
                                        for kk = 1:numel(pkn)
                                            nm = pkn{kk};
                                            if isfield(src, nm)
                                                tuple.(nm) = src.(nm);
                                            end
                                        end
                                    else
                                        tuple = src;
                                    end
                                end
                            catch
                            end
                            % Probe input value summary for first rows
                            if app.Debug && r <= app.DebugMaxRows
                                try
                                    xv = col(r);
                                    if iscell(xv), xv0 = xv{1}; else, xv0 = xv; end
                                    app.dbg('agg %s row %d xclass=%s xlen=%d tupleFields=%s', ...
                                        name, r, class(xv0), numel(xv0), strjoin(fieldnames(tuple),','));
                                catch
                                end
                            end
                            % x value for this row; if empty, fall back to fetchn by key
                            xval = col(r);
                            if isempty(xval) || (iscell(xval) && (isempty(xval{1})))
                                try
                                    % Prefer fetchn with LIMIT 1
                                    if exist('fetchn','file') == 2
                                        tmp = fetchn(app.Query & tuple, name, 'LIMIT', 1);
                                        if ~isempty(tmp)
                                            xval = tmp{1};
                                        end
                                    else
                                        xval = fetch1(app.Query & tuple, name);
                                    end
                                catch
                                    % leave xval as-is (likely empty)
                                end
                            end
                            out(r,1) = app.reduceScalar(xval, fh, tuple);
                            if app.Debug && r <= app.DebugMaxRows
                                app.dbg('agg %s row %d -> %g', name, r, out(r,1));
                            end
                        end
                        T.(name) = out;
                        % rename with suffix
                        label = app.aggregatorLabelForIndex(idx);
                        if ~isempty(label)
                            newName = matlab.lang.makeValidName([name '_' label]);
                            renameOld{end+1} = name; %#ok<AGROW>
                            renameNew{end+1} = newName; %#ok<AGROW>
                        end
                    end
                end
            end
            % Apply renames at once to avoid conflicts
            if ~isempty(renameOld)
                vn2 = T.Properties.VariableNames;
                for i = 1:numel(renameOld)
                    ix = find(strcmp(vn2, renameOld{i}), 1);
                    if ~isempty(ix)
                        vn2{ix} = renameNew{i};
                    end
                end
                T.Properties.VariableNames = vn2;
            end
        end

        function label = aggregatorLabelForIndex(app, idx)
            label = '';
            if isempty(idx) || idx<1 || idx>numel(app.AggSelectors) || ~isvalid(app.AggSelectors(idx))
                return
            end
            choice = app.AggSelectors(idx).Value;
            switch choice
                case {'mean','median'}
                    label = choice;
                case 'custom…'
                    if idx<=numel(app.CustomAggText) && ~isempty(app.CustomAggText{idx})
                        txt = string(app.CustomAggText{idx});
                        % If it's an '@func' or '@(x)...' text, try parse name
                        m = regexp(txt,'@([a-zA-Z_]\w*)','tokens','once');
                        if ~isempty(m)
                            label = m{1};
                        else
                            % Otherwise, use the bare function name or filename
                            try
                                [~, nm, ~] = fileparts(char(txt));
                                if ~isempty(nm)
                                    label = nm;
                                else
                                    label = char(txt);
                                end
                            catch
                                label = 'custom';
                            end
                        end
                    else
                        label = 'custom';
                    end
                otherwise
                    % Library function name
                    label = choice;
            end
        end

        function fh = aggregatorForIndex(app, idx)
            fh = [];
            if isempty(idx) || idx<1 || idx>numel(app.Selectors), return; end
            if idx>numel(app.AggSelectors) || ~isvalid(app.AggSelectors(idx)), return; end
            choice = app.AggSelectors(idx).Value;
            switch choice
                case 'mean'
                    % Three-arg wrapper; ignores tuple/query
                    fh = @(x,tuple,q)mean(x(:),'omitnan');
                case 'median'
                    % Three-arg wrapper; ignores tuple/query
                    fh = @(x,tuple,q)median(x(:),'omitnan');
                case 'custom…'
                    if idx<=numel(app.CustomAggFns) && ~isempty(app.CustomAggFns{idx})
                        basefh = app.CustomAggFns{idx};
                        % Wrapper calls with (x,tuple,q) if supported, else tries (x,q) then (x)
                        fh = @(x,tuple,q)app.invokeMaybeWithTupleAndQuery(basefh, x(:), tuple, q);
                    end
                otherwise
                    % Library function name
                    if isKey(app.AggLibMap, choice)
                        libfh = app.AggLibMap(choice);
                        fh = @(x,tuple,q)app.invokeMaybeWithTupleAndQuery(libfh, x(:), tuple, q);
                    end
            end
        end

        function y = reduceScalar(app, val, fh, tuple)
            % Normalize value to numeric vector then apply fh
            try
                v = val;
                if iscell(v)
                    if numel(v)==1, v = v{1}; else, v = cellfun(@double, v); end
                end
                if isstring(v)
                    v = double(str2double(v));
                elseif ischar(v)
                    v = double(str2double(v));
                elseif islogical(v)
                    v = double(v);
                end
                % If still non-numeric, try a best-effort cast; otherwise allow empty
                if ~isnumeric(v)
                    try
                        v = double(v);
                    catch
                        v = [];
                    end
                end
                v = v(:);  % vectorize; keep NaN/Inf for first try
                % First try with original vector to preserve indexing
                y = app.callAggregator(fh, v, tuple);
                % If invalid, try again with finite-only values
                if ~(isnumeric(y) && isscalar(y) && isfinite(y))
                    vfin = v(isfinite(v));
                    if isempty(vfin)
                        y = NaN; return
                    end
                    y = app.callAggregator(fh, vfin, tuple);
                end
                % Coerce to scalar double if needed
                if ~isscalar(y) || ~isnumeric(y) || ~isfinite(y)
                    y = double(y(1));
                end
            catch ME
                app.dbg('reduce error: %s', ME.message);
                y = NaN;
            end
        end

        function y = callAggregator(app, fh, v, tuple)
            % Call the aggregator wrapper with (x, tuple, q). The wrapper
            % adapts to user function arity internally.
            if nargin < 4
                tuple = struct();
            end
            y = fh(v, tuple, app.Query);
        end

        function y = invokeMaybeWithTupleAndQuery(app, basefh, x, tuple, q)
            % Helper to call user/library function with (x,tuple,q) when supported
            try
                n = nargin(basefh);
            catch
                n = -1; % unknown; assume varargs
            end
            try
                if n < 0 || n >= 3
                    y = basefh(x, tuple, q);
                elseif n == 2
                    % ambiguous: try (x,tuple) then (x,q)
                    try
                        y = basefh(x, tuple);
                    catch
                        y = basefh(x, q);
                    end
                elseif n == 1
                    y = basefh(x);
                else
                    y = basefh(x);
                end
            catch ME
                % Progressive fallbacks
                try
                    y = basefh(x, q);
                catch
                    try
                        y = basefh(x);
                    catch
                        rethrow(ME);
                    end
                end
            end
        end

        function dbg(app, fmt, varargin)
            % Lightweight debug printer controlled by app.Debug
            try
                if app.Debug
                    fprintf(['[Q2T] ' fmt '\n'], varargin{:});
                end
            catch
            end
        end

        function items = aggregationItems(app)
            % Base items plus any library functions
            items = [{'mean','median','custom…'}, app.AggLibraryNames];
        end

        function loadReducerLibrary(app)
            % Load custom reducer functions from env path or default
            try
                p = app.reducerBaseFolder();
                if isfolder(p)
                    addpath(p);
                    d = dir(fullfile(p,'*.m'));
                    names = {d.name};
                    names = erase(names, '.m');
                    % Do not execute functions during discovery; accept all .m files
                    app.AggLibraryNames = names;
                    fhList = cellfun(@str2func, names, 'UniformOutput', false);
                    app.AggLibMap = containers.Map(names, fhList);
                    % Update existing agg dropdowns
                    for i = 1:numel(app.AggSelectors)
                        if isvalid(app.AggSelectors(i))
                            app.AggSelectors(i).Items = aggregationItems(app);
                        end
                    end
                end
            catch
                % ignore errors; library optional
            end
        end

        function p = reducerBaseFolder(app)
            % Determine the base folder for reducer functions from env or default
            try
                p = getenv('BLOB_REDUCER_PATH');
                if isempty(p)
                    home = char(java.lang.System.getProperty('user.home'));
                    p = fullfile(home,'analysis','blob_reducer_functions');
                end
                % Expand leading '~'
                if startsWith(p,'~')
                    home = char(java.lang.System.getProperty('user.home'));
                    p = fullfile(home, p(2:end));
                end
            catch
                p = pwd;
            end
        end

        function exportData(app)
            attrs = selectedAttributeNames(app);
            if isempty(attrs)
                uialert(app.UIFigure,'No columns selected to export.','Nothing to Export'); return
            end
            if isempty(app.Query)
                uialert(app.UIFigure,'No query set.','Nothing to Export'); return
            end

            % Format from dropdown
            choice = app.ExportFormatDropDown.Value;

            switch choice
                case 'CSV'
                    [f,p] = uiputfile({'*.csv','CSV File (*.csv)'}, 'Save CSV');
                case 'MAT-Struct'
                    [f,p] = uiputfile({'*.mat','MAT-file (*.mat)'}, 'Save MAT (struct)');
                case 'HDF5'
                    [f,p] = uiputfile({'*.h5;*.hdf5','HDF5 File (*.h5, *.hdf5)'}, 'Save HDF5');
                otherwise % 'MAT-Table'
                    [f,p] = uiputfile({'*.mat','MAT-file (*.mat)'}, 'Save MAT (table)');
            end
            if isequal(f,0), return; end
            file = fullfile(p,f);

            % Fetch full dataset (no limit)
            try
                % Include primary keys for tuple support
                pk = app.primaryKeyNames();
                fetchAttrs = attrs;
                for i = 1:numel(pk)
                    if ~any(strcmp(fetchAttrs, pk{i})), fetchAttrs{end+1} = pk{i}; end %#ok<AGROW>
                end
                if isempty(pk)
                    fetchAttrs{end+1} = 'KEY'; %#ok<AGROW>
                end
                S = fetch(app.Query, fetchAttrs{:});
                if isempty(S)
                    varTypes = repmat({'string'}, 1, numel(attrs));
                    T = table('Size',[0 numel(attrs)], 'VariableTypes',varTypes, 'VariableNames',attrs);
                else
                    T = struct2table(S);
                    % Stash struct rows for tuple-aware aggregations
                    app.LastStruct = S;
                    keep = intersect(attrs, T.Properties.VariableNames, 'stable');
                    T = T(:, keep);
                    % Apply aggregations (so export reflects choices for blob columns)
                    T = applyAggregations(app, T);
                end
                % Units mapping for the selected attrs
                units = app.getUnitsForAttributes(T.Properties.VariableNames);
            catch ME
                uialert(app.UIFigure,sprintf('Export fetch failed:\n%s',ME.message),'DataJoint Error');
                return
            end

            try
                switch choice
                    case 'CSV'
                        app.writeCSVWithUnits(file, T, units);
                    case 'MAT-Struct'
                        data = table2struct(T); %#ok<NASGU>
                        unitsStruct = app.unitsStruct(T.Properties.VariableNames, units); %#ok<NASGU>
                        save(file,'data','unitsStruct');
                    case 'HDF5'
                        exportToHDF5(app, T, file);
                    otherwise % 'MAT-Table'
                        T = T; %#ok<NASGU>
                        unitsStruct = app.unitsStruct(T.Properties.VariableNames, units); %#ok<NASGU>
                        save(file,'T','unitsStruct');
                end
            catch ME
                uialert(app.UIFigure,sprintf('Save failed:\n%s',ME.message),'Export Error');
            end
        end

        function exportToHDF5(app, T, file)
            % Build groups from column 1; write other columns as datasets
            if isempty(T)
                % create empty file
                fid = H5F.create(file,'H5F_ACC_TRUNC','H5P_DEFAULT','H5P_DEFAULT');
                H5F.close(fid);
                return
            end
            if exist(file,'file'), delete(file); end
            colNames = T.Properties.VariableNames;
            keyColName = colNames{1};
            keys = app.toStrings(T{:,1});
            % Enforce uniqueness of key values
            try
                [u,~,ic] = unique(keys,'stable');
                counts = accumarray(ic(:),1,[numel(u) 1]);
                dups = u(counts>1);
            catch
                % Fallback if unique fails on types: skip grouping
                dups = {};
            end
            if ~isempty(dups)
                preview = strjoin(dups(1:min(5,end)), ', ');
                uialert(app.UIFigure, sprintf('HDF5 export requires unique keys in column 1 ("%s"). Duplicate values: %s', keyColName, preview), 'Duplicate Keys');
                return
            end
            % Write units group
            units = app.getUnitsForAttributes(colNames);
            app.ensureGroup(file,'/units');
            for j = 1:numel(colNames)
                app.h5writeString(file, ['/units/' colNames{j}], string(units{j}));
            end
            % Iterate rows and write datasets per group
            for i = 1:height(T)
                grp = ['/' keyColName '_' app.sanitizeForPath(keys{i})];
                app.ensureGroup(file, grp);
                for j = 2:width(T)
                    ds = [grp '/' colNames{j}];
                    val = T{i,j};
                    if iscell(val)
                        if numel(val)==1, val = val{1}; end
                    end
                    if iscellstr(val)
                        val = string(val{1});
                    end
                    if isstring(val) || ischar(val) || iscategorical(val) || isdatetime(val) || isduration(val)
                        app.h5writeString(file, ds, string(val));
                    elseif isnumeric(val) || islogical(val)
                        data = val;
                        if isempty(data), data = NaN; end
                        if isscalar(data)
                            sz = [1 1];
                        else
                            sz = size(data);
                        end
                        h5create(file, ds, sz);
                        h5write(file, ds, data);
                    else
                        % Fallback: write textual representation
                        app.h5writeString(file, ds, string(mat2str(val)));
                    end
                end
            end
        end

        function s = sanitizeForPath(~, s)
            s = char(s);
            s = strtrim(s);
            s = regexprep(s,'[\/]+','-');
            s = regexprep(s,'\s+','_');
        end

        function arr = toStrings(~, v)
            if iscell(v)
                arr = cellfun(@(x)string(x), v, 'UniformOutput', false);
                arr = cellfun(@char, arr, 'UniformOutput', false);
            elseif isstring(v)
                arr = cellstr(v);
            elseif isnumeric(v) || islogical(v)
                arr = arrayfun(@(x)num2str(x), v, 'UniformOutput', false);
            elseif ischar(v)
                arr = cellstr(v);
            else
                arr = arrayfun(@(x)char(string(x)), v, 'UniformOutput', false);
            end
        end

        function ensureGroup(~, file, groupPath)
            % Recursively ensure an HDF5 group exists
            if isempty(groupPath) || groupPath(1) ~= '/'
                groupPath = ['/' groupPath]; %#ok<AGROW>
            end
            if ~exist(file,'file')
                fid = H5F.create(file,'H5F_ACC_TRUNC','H5P_DEFAULT','H5P_DEFAULT');
            else
                fid = H5F.open(file,'H5F_ACC_RDWR','H5P_DEFAULT');
            end
            parts = strsplit(groupPath,'/');
            curr = '';
            for k = 2:numel(parts)
                if isempty(parts{k}), continue; end
                curr = [curr '/' parts{k}]; %#ok<AGROW>
                % Try open; if fails, create
                try
                    gid = H5G.open(fid, curr);
                catch
                    gid = H5G.create(fid, curr, 0, 0, 0);
                end
                H5G.close(gid);
            end
            H5F.close(fid);
        end

        function h5writeString(~, file, dataset, strVal)
            % Write a scalar string dataset (variable-length)
            s = string(strVal);
            try
                h5create(file, dataset, 1, 'Datatype','string');
            catch
                % If already exists, attempt to overwrite
            end
            h5write(file, dataset, s);
        end

        function writeCSVWithUnits(app, file, T, units)
            vn = T.Properties.VariableNames;
            % Write header + units lines manually, then append data
            fid = fopen(file,'w');
            if fid==-1
                error('Could not open file for writing: %s', file);
            end
            % Header
            fprintf(fid, '%s\n', strjoin(vn, ','));
            % Units line (quoted if needed)
            unitCells = cell(1,numel(units));
            for i = 1:numel(units)
                u = string(units{i});
                uc = char(u);
                if contains(uc, [',', '"'])
                    uc = ['"' strrep(uc,'"','""') '"'];
                end
                unitCells{i} = uc;
            end
            fprintf(fid, '%s\n', strjoin(unitCells, ','));
            fclose(fid);
            % Append table data without variable names
            writetable(T, file, 'WriteMode','append', 'WriteVariableNames', false);
        end

        function units = getUnitsForAttributes(app, attrs)
            % Build units list corresponding to attrs, using the first
            % occurrence of each attribute in the selectors.
            units = repmat({''}, 1, numel(attrs));
            seen = containers.Map('KeyType','char','ValueType','logical');
            for i = 1:numel(app.Selectors)
                name = app.Selectors(i).Value;
                if ~isKey(seen, name)
                    seen(name) = true;
                    idx = find(strcmp(attrs, name), 1, 'first');
                    if ~isempty(idx)
                        if i <= numel(app.UnitEditors) && isvalid(app.UnitEditors(i))
                            units{idx} = app.UnitEditors(i).Value;
                        end
                    end
                end
            end
            % Fallback: if some attrs were not matched due to renaming with
            % aggregation suffixes, try stripping the suffix after the last '_'
            for k = 1:numel(attrs)
                if units{k} == "" || (iscell(units) && isempty(units{k}))
                    nm = attrs{k};
                    us = strfind(nm,'_');
                    if ~isempty(us)
                        base = nm(1:us(end)-1);
                        if isKey(seen, base)
                            % find the selector index for base
                            ii = find(arrayfun(@(d)strcmp(d.Value,base), app.Selectors), 1, 'first');
                            if ~isempty(ii) && ii <= numel(app.UnitEditors) && isvalid(app.UnitEditors(ii))
                                units{k} = app.UnitEditors(ii).Value;
                            end
                        end
                    end
                end
            end
        end

        function s = unitsStruct(~, varNames, units)
            s = struct();
            for i = 1:numel(varNames)
                s.(varNames{i}) = units{i};
            end
        end

        function saveStateToMat(app)
            attrs = selectedAttributeNames(app);
            units = app.getUnitsForAttributes(attrs);
            % Per-selector state
            selAttrs = arrayfun(@(d)d.Value, app.Selectors, 'UniformOutput', false);
            selUnits = arrayfun(@(e)string(e.Value), app.UnitEditors, 'UniformOutput', false);
            selUnits = cellfun(@char, selUnits, 'UniformOutput', false);
            selAggs = cell(1, numel(app.AggSelectors));
            selAggCustomTxt = cell(1, numel(app.AggSelectors));
            for i = 1:numel(app.AggSelectors)
                if isvalid(app.AggSelectors(i))
                    selAggs{i} = app.AggSelectors(i).Value;
                else
                    selAggs{i} = '';
                end
                if i<=numel(app.CustomAggText)
                    selAggCustomTxt{i} = app.CustomAggText{i};
                else
                    selAggCustomTxt{i} = '';
                end
            end
            state = struct('SelectedAttributes',{attrs}, 'Units',{units}, 'Version', 3, ...
                           'SelectorAttributes',{selAttrs}, 'SelectorUnits',{selUnits}, ...
                           'SelectorAggregations',{selAggs}, 'SelectorCustomText',{selAggCustomTxt});
            [f,p] = uiputfile({'*.mat','MAT-file (*.mat)'}, 'Save App State');
            if isequal(f,0), return; end
            file = fullfile(p,f);
            try
                save(file,'state');
            catch ME
                uialert(app.UIFigure,sprintf('Could not save state:\n%s',ME.message),'Save Error');
            end
        end

        function loadStateFromMat(app)
            [f,p] = uigetfile({'*.mat','MAT-file (*.mat)'}, 'Load App State');
            if isequal(f,0), return; end
            file = fullfile(p,f);
            try
                S = load(file);
                if isfield(S,'state') && isfield(S.state,'SelectedAttributes')
                    attrs = S.state.SelectedAttributes;
                    if isfield(S.state,'Units')
                        units = S.state.Units;
                    else
                        units = repmat({''},1,numel(attrs));
                    end
                    if isfield(S.state,'SelectorAttributes')
                        selAttrs = S.state.SelectorAttributes;
                    else
                        selAttrs = attrs;
                    end
                    if isfield(S.state,'SelectorUnits')
                        selUnits = S.state.SelectorUnits;
                    else
                        selUnits = units;
                    end
                    if isfield(S.state,'SelectorAggregations')
                        selAggs = S.state.SelectorAggregations;
                    else
                        selAggs = repmat({'mean'},1,numel(selAttrs));
                    end
                    if isfield(S.state,'SelectorCustomText')
                        selAggCustomTxt = S.state.SelectorCustomText;
                    else
                        selAggCustomTxt = repmat({''},1,numel(selAttrs));
                    end
                elseif isfield(S,'SelectedAttributes')
                    attrs = S.SelectedAttributes; % fallback if user saved raw
                    if isfield(S,'Units')
                        units = S.Units;
                    else
                        units = repmat({''},1,numel(attrs));
                    end
                    selAttrs = attrs; selUnits = units;
                    selAggs = repmat({'mean'},1,numel(selAttrs));
                    selAggCustomTxt = repmat({''},1,numel(selAttrs));
                else
                    uialert(app.UIFigure,'MAT file does not contain a valid state.','Load Error');
                    return
                end
                if isstring(attrs), attrs = cellstr(attrs); end
                if ~iscell(attrs), uialert(app.UIFigure,'State has invalid attribute list.','Load Error'); return; end

                % Clear current selectors
                if ~isempty(app.Selectors)
                    for i = numel(app.Selectors):-1:1
                        dd = app.Selectors(i);
                        delete(ancestor(dd,'matlab.ui.container.GridLayout'));
                    end
                    app.Selectors = matlab.ui.control.DropDown.empty;
                    app.AggSelectors = matlab.ui.control.DropDown.empty;
                    app.UnitEditors = matlab.ui.control.EditField.empty;
                    app.CustomAggFns = {};
                end

                % Recreate selectors in saved order (per selector)
                for i = 1:numel(selAttrs)
                    addSelector(app, selAttrs{i});
                    if i<=numel(selUnits)
                        app.UnitEditors(i).Value = selUnits{i};
                    end
                    % Set aggregation choice (if this is a blob attribute)
                    if i<=numel(app.AggSelectors) && isvalid(app.AggSelectors(i))
                        items = app.AggSelectors(i).Items;
                        val = selAggs{i};
                        if ~any(strcmp(val, items))
                            % if library not present yet, try to load
                            loadReducerLibrary(app);
                            items = app.AggSelectors(i).Items;
                        end
                        if any(strcmp(val, items))
                            app.AggSelectors(i).Value = val;
                        end
                        % restore custom function if needed
                        if strcmp(val,'custom…') && i<=numel(selAggCustomTxt)
                            txt = selAggCustomTxt{i};
                            if ~isempty(txt)
                                try
                                    fh = str2func(txt);
                                    app.CustomAggFns{i} = fh;
                                    app.CustomAggText{i} = txt;
                                catch
                                end
                            end
                        end
                    end
                end
                layoutSelectors(app);
                refreshPreview(app, true);
            catch ME
                uialert(app.UIFigure,sprintf('Could not load state:\n%s',ME.message),'Load Error');
            end
        end
        function updateTableView(app)
            % Show only the first N rows; toggle table visibility
            T = app.CurrentTable;
            if isempty(T)
                app.PreviewTable.Data = T; 
                app.PreviewTable.Visible = app.ShowTableCheckBox.Value;
                return
            end
            n = height(T);
            maxRows = max(1, round(app.MaxPreviewRows));
            T10 = T(1:min(maxRows,n), :);

            app.PreviewTable.Data = T10;
            app.PreviewTable.Visible = app.ShowTableCheckBox.Value;
        end

        function onRowsChanged(app)
            app.MaxPreviewRows = max(1, round(app.RowsSpinner.Value));
            updateTableView(app);
        end
    end

    methods (Access = public)
        function T = getOutputTable(app)
            if isempty(app.CurrentTable), refreshPreview(app); end
            T = app.CurrentTable;
        end
    end
end
