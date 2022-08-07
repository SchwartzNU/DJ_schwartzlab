function [] = copy_animal_events_from_sl_animal(animal_id)
events_struct = fetch(sl.AnimalEvent.all & sprintf('animal_id=%d',animal_id), '*');
N_events = length(events_struct);
fprintf('Copying %d animal events from sl to sln_animal\n', N_events);

for i=1:N_events
    i
    curEvent = events_struct(i);
    % list of sl animal events
    switch curEvent.event_type
        case 'ActivateBreedingCage'
        case 'AssignCage'
            ev = fetch(sl.AnimalEventAssignCage & sprintf('event_id=%d',curEvent.event_id),'*');
            ev = rmfield(ev,'event_id');
            ev_cage = rmfield(ev,'room_number');
            cage_int = str2double(ev_cage.cage_number);
            if ~isnan(cage_int)
                ev_cage.cage_number = cage_int;
                thisEvent = sln_animal.AnimalEvent * sln_animal.AssignCage & sprintf('animal_id=%d',ev.animal_id) & sprintf('entry_time="%s"',ev.entry_time);
                if thisEvent.exists
                    thisEvent_struct = fetch(thisEvent);
                    for j=1:length(thisEvent_struct)
                        del(sln_animal.AnimalEvent & sprintf('event_id=%d',thisEvent_struct(j).event_id)); %delete duplicates
                    end
                end
                sln_animal.add_event(ev_cage,'AssignCage');
                ev_room = rmfield(ev,{'time','cause','notes','animal_id'});
                ev_room.cage_number = cage_int;
                thisRoomAssign = sln_animal.CageAssignRoom & ev_room;
                if ~thisRoomAssign.exists
                    insert(sln_animal.CageAssignRoom, ev_room);
                end
            else
                fprintf('Could not copy AssignCage event for animal %d cage number %s because cage number is not an integer.\n', ev.animal_id, ev.cage_number);
            end
        case 'AssignProtocol'
            ev = fetch(sl.AnimalEventAssignProtocol & sprintf('event_id=%d',curEvent.event_id),'*');
            ev = rmfield(ev,'event_id');
            thisEvent = sln_animal.AnimalEvent * sln_animal.AssignProtocol & sprintf('animal_id=%d',ev.animal_id) & sprintf('entry_time="%s"',ev.entry_time);
            if thisEvent.exists
                thisEvent_struct = fetch(thisEvent);
                for j=1:length(thisEvent_struct)
                    del(sln_animal.AnimalEvent & sprintf('event_id=%d',thisEvent_struct(j).event_id)); %delete duplicates
                end
            end
            sln_animal.add_event(ev,'AssignProtocol');
        case 'BrainInjection'
        case 'DeactivateBreedingCage'
        case 'Deceased'
            ev = fetch(sl.AnimalEventDeceased & sprintf('event_id=%d',curEvent.event_id),'*');
            ev = rmfield(ev,'event_id');
            thisEvent = sln_animal.AnimalEvent * sln_animal.Deceased & sprintf('animal_id=%d',ev.animal_id) & sprintf('entry_time="%s"',ev.entry_time);
            if thisEvent.exists
                thisEvent_struct = fetch(thisEvent);
                for j=1:length(thisEvent_struct)
                    del(sln_animal.AnimalEvent & sprintf('event_id=%d',thisEvent_struct(j).event_id)); %delete duplicates
                end
            end
            sln_animal.add_event(ev,'Deceased');
        case 'EyeInjection'
        case 'GaveBirth'
        case 'Feed'
        case 'Genotyped'
        case 'IPinjection'
        case 'PairBreeders'
        case 'ReservedForProject'
            ev = fetch(sl.AnimalEventReservedForProject & sprintf('event_id=%d',curEvent.event_id),'*');
            ev = rmfield(ev,'event_id');
            thisEvent = sln_animal.AnimalEvent * sln_animal.ReservedForProject & sprintf('animal_id=%d',ev.animal_id) & sprintf('entry_time="%s"',ev.entry_time);
            if thisEvent.exists
                thisEvent_struct = fetch(thisEvent);
                for j=1:length(thisEvent_struct)
                    del(sln_animal.AnimalEvent & sprintf('event_id=%d',thisEvent_struct(j).event_id)); %delete duplicates
                end
            end          
            sln_animal.add_event(ev,'ReservedForProject');
        case 'ReservedForSession'
            ev = fetch(sl.AnimalEventReservedForSession & sprintf('event_id=%d',curEvent.event_id),'*');
            ev = rmfield(ev,'event_id');
            thisEvent = sln_animal.AnimalEvent * sln_animal.ReservedForSession & sprintf('animal_id=%d',ev.animal_id) & sprintf('entry_time="%s"',ev.entry_time);
            if thisEvent.exists
                thisEvent_struct = fetch(thisEvent);
                for j=1:length(thisEvent_struct)
                    del(sln_animal.AnimalEvent & sprintf('event_id=%d',thisEvent_struct(j).event_id)); %delete duplicates
                end
            end
            sln_animal.add_event(ev,'ReservedForSession');
        case 'RetireAsBreeder'
        case 'SeparateBreeders'
        case 'SetAsBreeder'
        case 'SocialBehaviorSession'
            ev = fetch(sl.AnimalEventSocialBehaviorSession & sprintf('event_id=%d',curEvent.event_id),'*');
            ev = rmfield(ev,'event_id');
            thisEvent = sln_animal.AnimalEvent * sln_animal.SocialBehaviorSession & sprintf('animal_id=%d',ev.animal_id) & sprintf('entry_time="%s"',ev.entry_time);
            if thisEvent.exists
                thisEvent_struct = fetch(thisEvent);
                for j=1:length(thisEvent_struct)
                    del(sln_animal.AnimalEvent & sprintf('event_id=%d',thisEvent_struct(j).event_id)); %delete duplicates
                end
            end
            sln_animal.add_event(ev,'SocialBehaviorSession');
        case 'Tag'
            ev = fetch(sl.AnimalEventTag & sprintf('event_id=%d',curEvent.event_id),'*');
            ev = rmfield(ev,'event_id');
            thisEvent = sln_animal.AnimalEvent * sln_animal.Tag & sprintf('animal_id=%d',ev.animal_id) & sprintf('entry_time="%s"',ev.entry_time);
            if thisEvent.exists
                thisEvent_struct = fetch(thisEvent);
                for j=1:length(thisEvent_struct)
                    del(sln_animal.AnimalEvent & sprintf('event_id=%d',thisEvent_struct(j).event_id)); %delete duplicates
                end
            end
            sln_animal.add_event(ev,'Tag');
        case 'Weaned'


    end
end



% %% Deceased
% deceased_events_struct = rmfield(fetch(sl.AnimalEventDeceased,'*'), 'event_id');
% for i=1:length(deceased_events_struct)
%     sln_animal.add_event(deceased_events_struct(i), 'Deceased', 'REPLACE');
% end
% 
% %% Assign protocol
% assign_protocol_events_struct = rmfield(fetch(sl.AnimalEventAssignProtocol  ,'*'), 'event_id');
% for i=1:length(assign_protocol_events_struct)
%     i
%     sln_animal.add_event(assign_protocol_events_struct(i), 'AssignProtocol', 'REPLACE');
% end
% 
% %% Brain injection
% brain_inj_events_struct = rmfield(fetch(sl.AnimalEventBrainInjection  ,'*'), 'event_id');
% N = length(brain_inj_events_struct)
% for i=1:length(brain_inj_events_struct)
%     i
%     sln_animal.add_event(brain_inj_events_struct(i), 'BrainInjection', 'REPLACE');
% end
% 
% %% Eye injection
% eye_inj_events_struct = rmfield(fetch(sl.AnimalEventEyeInjection  ,'*'), 'event_id');
% N = length(eye_inj_events_struct)
% for i=1:N
%     i
%     sln_animal.add_event(eye_inj_events_struct(i), 'EyeInjection', 'REPLACE');
% end
% 
% %% Social Behavior session
% soc_beh_session_events_struct = fetch(sl.AnimalEventSocialBehaviorSession  ,'*');
% N = length(soc_beh_session_events_struct)
% for i=1:N
%     i
%     sln_animal.add_event(soc_beh_session_events_struct(i), 'SocialBehaviorSession', 'REPLACE');
% end
% 
% %% Reserved for session
% res_session_events_struct = rmfield(fetch(sl.AnimalEventReservedForSession  ,'*'), 'event_id');
% N = length(res_session_events_struct)
% for i=1:N
%     i
%     sln_animal.add_event(res_session_events_struct(i), 'ReservedForSession', 'REPLACE');
% end
% 
% %% Tag
% tag_events_struct = rmfield(fetch(sl.AnimalEventTag  ,'*'), 'event_id');
% N = length(tag_events_struct)
% for i=1:N
%     i
%     sln_animal.add_event(tag_events_struct(i), 'Tag', 'REPLACE');
% end
% 
% %% Reserved for Project
% res_project_events_struct = rmfield(fetch(sl.AnimalEventReservedForProject  ,'*'), 'event_id');
% N = length(res_project_events_struct)
% for i=1:N
%     i
%     sln_animal.add_event(res_project_events_struct(i), 'ReservedForProject', 'REPLACE');
% end
% 
% %% Assign cage
% assign_cage_events_struct = rmfield(fetch(sl.AnimalEventAssignCage  ,'*'), 'event_id');
% N = length(assign_cage_events_struct)
% for i=1:N
%     i
%     cage_int = str2double(assign_cage_events_struct(i).cage_number);
%     if ~isnan(cage_int) %can't add the non-numeric cage numbers
%         assign_cage_events_struct(i).cage_number = cage_int;
%         sln_animal.add_event(assign_cage_events_struct(i), 'AssignCage', 'REPLACE');
%     end
% end

%