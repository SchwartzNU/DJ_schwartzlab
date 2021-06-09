function [] = addAllTagIDs()
all_DJID = fetch(sl.Animal, 'tag_id', 'dob', 'tag_ear', 'punch');

for i=1:length(all_DJID)    
    key.animal_id = all_DJID(i).animal_id;
    if ~isempty(all_DJID(i).dob)
        key.date = all_DJID(i).dob;
    end
    key.user_name = 'sl_user';
    key.tag_ear = all_DJID(i).tag_ear;
    key.punch = all_DJID(i).punch;
    key.tag_id = all_DJID(i).tag_id;
    add_animalEvent(key, 'Tag');
end
