function [] = load_annotation_file_for_session(event_id)

annotations_in_db = sl_behavior.Annotation & sprintf('event_id=%d', event_id);
if annotations_in_db.exists
    answer = input(sprintf('%d existing annotations for this session found in database. Replace? [y|n]: ', annotations_in_db.count), 's');
    if ~strcmp(answer, 'y')
        disp('aborting');
        return
    end
end

behavior_master_folder = [getenv("SERVER") filesep 'BehaviorMaster' filesep];

header_lines = 18; %TODO make a variable
%TODO, read in pup number... and other possible variables

fname = folder_name_from_behavior_session(event_id);
event_table = readtable(sprintf('%s%s%s%d.csv', behavior_master_folder, fname, filesep, event_id), ...
    'NumHeaderLines', header_lines, 'VariableNamesLine',header_lines+1,'delimiter',',');

N_events = height(event_table);
frame_rate = event_table.FPS(1);

state_map = containers.Map;
for i=1:N_events
    fprintf('Loading %d of %d\n', i, N_events);
    cur_event = event_table.Behavior{i};
    thisEventType = fetch(sl_behavior.AnnotationType & sprintf('annotation_name="%s"', cur_event), '*');

    if strcmp(thisEventType.type, 'state')
        if isKey(state_map, cur_event) %close it
            if ~strcmp(event_table.Status{i}, 'STOP')
                thisEventType
                error('This should be a STOP event');
            end
            end_frame = round(event_table.Time(i) * frame_rate);
            key_state = state_map(cur_event);
            key_state.duration = end_frame - key_state.frame;
            try
                insert(sl_behavior.Annotation, key_state, 'REPLACE');
            catch ME
                fprintf('Error on state key insert %s\n', ME.message);
            end
            %delete the entry in the map
            remove(state_map, cur_event);

        else %open it            
            %should be a start event
            if ~strcmp(event_table.Status{i}, 'START')
                error('This should be a START event');
            end
            key_state.event_id = event_id;
            key_state.annotation_name = cur_event;
            key_state.frame = round(event_table.Time(i) * frame_rate);      
            if strcmp(thisEventType.has_modifier, 'T')
                key_state.modifier = event_table.Modifier1{i};
            end
            state_map(cur_event) = key_state;
        end

    else
        key.annotation_name = cur_event;
        key.event_id = event_id;
        key.frame = round(event_table.Time(i) * frame_rate);

        if strcmp(thisEventType.has_modifier, 'T')
            key.modifier = event_table.Modifier1{i};
        end

        try
            insert(sl_behavior.Annotation, key, 'REPLACE');
        catch ME
            fprintf('Error on point key insert %s\n', ME.message);
        end
    end

end




