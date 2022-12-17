
%{
# The results of a Symphony calibration session
calibration_id: smallint unsigned auto_increment
---
calibration_name = NULL : varchar(64)
canvas_width : smallint unsigned
canvas_height : smallint unsigned
#canvas_x: smallint
#canvas_y: smallint

frame_tracker_width: smallint unsigned
frame_tracker_height: smallint unsigned
frame_tracker_x: smallint
frame_tracker_y: smallint
frame_tracker_duration: float

microns_per_pixel: float

image_orientation_x: enum('reverse','normal')
image_orientation_y: enum('reverse','normal')
angle_offset: float

%}
classdef Calibration < dj.Manual
    properties (Access = {?sln_symphony.Experiment})
        canInsert = true;
    end
    methods
        function ind = insert(self,map)
            if ~self.canInsert
                error('You cannot insert into this table directly. Insert an Experiment instead.');
            end
            key = struct();
            
            mapKeys = map.keys();
            if any(strcmp(mapKeys,'rigProperty'))
                rigProperty = map('rigProperty');
                key.calibration_name = rigProperty(1).value;
            end
            
            %% Stage settings
            orientations = {'normal','reverse'};
            if ~any(contains(mapKeys,'LightCrafter'))
                disp('Not inserting calibration')
                ind = 247; %247 is the index of the null calibration
                return;
            end
            lcr = map(mapKeys{contains(mapKeys,'LightCrafter')});
            for prop = lcr
                switch prop.name
                    case 'trueCanvasSize'
                        key.canvas_width = prop.value(1);
                        key.canvas_height = prop.value(2);
                    % case 'canvasTranslation'
                    %     key.canvas_x = prop.value(1);
                    %     key.canvas_y = prop.value(2);
                    case 'frameTrackerSize'
                        key.frame_tracker_width = prop.value(1);
                        key.frame_tracker_height = prop.value(2);
                    case 'frameTrackerPosition'
                        key.frame_tracker_x = prop.value(1);
                        key.frame_tracker_y = prop.value(2);
                    case 'frameTrackerDuration'
                        key.frame_tracker_duration = prop.value;
                    case 'micronsPerPixel'
                        key.microns_per_pixel = prop.value;
                    case 'imageOrientation'
                        key.image_orientation_x = orientations{prop.value(1)+1};
                        key.image_orientation_y = orientations{prop.value(2)+1};
                    case 'angleOffset'
                        key.angle_offset = prop.value;
                end
            end
            
            %% NDF Settings
            ndf = map('neutralDensityFilterWheel');
            ndf_values = num2cell(ndf(2).value);
            n_ndfs = numel(ndf_values);
            
            %% LED Settings
            ledNames = mapKeys(contains(mapKeys,'fit'));
            
            emp = cell(numel(ledNames),1);
            leds = struct('color',emp,...
                'rod_overlap',emp,'m_cone_overlap',emp,'s_cone_overlap',emp,...
                'fit_1',0,'fit_2',0,'fit_3',0,...
                'fit_4',0,'fit_5',0,'fit_6',0);
            
            emp = cell(numel(ledNames) * n_ndfs, 1);
            led_ndfs = struct('color',emp,'value',emp,'attenuation',emp);
            fit_names = {'fit_1','fit_2','fit_3','fit_4','fit_5','fit_6'};
            
            for i = 1:numel(ledNames)
                led = ledNames{i}(4:end);
                leds(i).color = led;
                
                try
                    overlaps = map(sprintf('spectralOverlap_%s', led));
                    leds(i).rod_overlap = overlaps(1);
                    leds(i).s_cone_overlap = overlaps(2);
                    leds(i).m_cone_overlap = overlaps(3);
                catch
                    disp('spectral overlaps not found in calibration');
                end
                
                fits = map(ledNames{i});
                for j = 1:numel(fits)
                    leds(i).(fit_names{j}) = fits(end - j + 1);
                end
                
                try
                    attenuations = num2cell(map(sprintf('filterWheelAttenuationValues_%s', led)));
                    [led_ndfs(n_ndfs*(i-1)+1 : n_ndfs*(i)).attenuation] = attenuations{:};
                    [led_ndfs(n_ndfs*(i-1)+1 : n_ndfs*(i)).color] = deal(led);
                    [led_ndfs(n_ndfs*(i-1)+1 : n_ndfs*(i)).value] = ndf_values{:};
                catch
                    disp('attenuation values by LED not found in calibration');
                end

                
            end

            colors = lower(unique({leds(:).color}));
            existing_leds = fetch(sln_symphony.LED & struct('color',colors));
            missing_leds = setdiff(colors, {existing_leds(:).color});
            if ~isempty(missing_leds)
                missing_text = sprintf('\n\t> %s',missing_leds{:});
                names_text = sprintf('''%s'',',missing_leds{:});
                missing_text = sprintf(...
                    '%s\nTo insert all, use:\n\tsln_symphony.LED().insert({%s}'');',...
                    missing_text,names_text(1:end-1));
                error(['LEDs were missing from the database. '...
                    'You must manually insert these in '...
                    'the LED table or rename them in the key:%s'], missing_text); %#ok<SPERR>
            end
            
            %search for this set of parameters
            if isempty(leds(1).rod_overlap)
                disp('Not inserting calibration')
                ind = 247; %247 is the index of the null calibration
            else
                q = (self & key) * (sln_symphony.CalibrationLED & leds) * (sln_symphony.CalibrationLEDAttenuation & led_ndfs);

                if count(q) == numel(led_ndfs) %this calibration already exists
                    ind = fetch1(q,'calibration_id');
                else
                    insert@dj.Manual(self, key);
                    ind = self.lastInsertID;

                    table = sln_symphony.CalibrationNDF();
                    table.canInsert = true;
                    table.insert(struct('calibration_id',ind,'value',ndf_values));


                    [leds(:).calibration_id] = deal(ind);
                    table = sln_symphony.CalibrationLED();
                    table.canInsert = true;
                    table.insert(leds);s

                    [led_ndfs(:).calibration_id] = deal(ind);
                    table = sln_symphony.CalibrationLEDAttenuation();
                    table.canInsert = true;
                    table.insert(led_ndfs);
                end
            end
        end
    end
    
end