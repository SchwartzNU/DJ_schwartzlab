function folder_name = matchSessionToBehaviorFolder(session_id, rootFolder)
folder_name = '';
thisSession = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('event_id=%d',session_id);
thisSession_struct = fetch(thisSession,'*');
animal_id = thisSession_struct.animal_id;
session_date = thisSession_struct.date;

temp = dir([rootFolder filesep num2str(animal_id)]);
session_folders = {temp.name};

N = length(session_folders);
date_first = false(N,1);
for i=1:N
    cur_folder = session_folders{i};
    if ~startsWith(cur_folder, '.') && strcmp(cur_folder(5), '-')
        date_first(i) = true;
    end
end

date_match = false(N,1);
for i=1:N
    cur_folder = session_folders{i};
    if ~startsWith(cur_folder, '.')
        if date_first(i)
            date_match(i) = strcmp(cur_folder(1:10),session_date);
        else
            cur_folder = extractAfter(cur_folder, '_');
            date_match(i) = strcmp(cur_folder(1:10),session_date);
        end
    end
end

folders_matching_date = session_folders(date_match);

N_date_match = length(folders_matching_date);
if N_date_match==0
    fprintf('No matching folder found for animal %d, date %s\n', animal_id, session_date);
    folder_name = 'none';
elseif N_date_match==1
    disp('single match found');
    folder_name = folders_matching_date;
else %multiple matches
    match_table = table('Size',[N_date_match, 2],'VariableNames',{'index', 'folder_name'},'VariableTypes',{'uint16','string'});
    for i=1:N_date_match
        match_table.index(i) = i;
        match_table.folder_name(i) = folders_matching_date{i};
    end
    thisSession_struct
    match_table
    %index_selected = 1;
    index_selected = input('Select matching index or 0 for no match: ');
    if index_selected==0
        fprintf('No matching folder selected for animal %d, date %s\n', animal_id, session_date);
        folder_name = 'none';
    else
        disp('Match selected');
        folder_name = match_table.folder_name(index_selected);
    end
end
