classdef ROI_method_chooser_dlg < handle

    % Properties that correspond to app components
    properties (Access = public)
        ROIMethodChooserUIFigure       matlab.ui.Figure
        OKButton                       matlab.ui.control.Button
        NameLabel                      matlab.ui.control.Label
        NameEditField                  matlab.ui.control.EditField
        AddnewmethodButton             matlab.ui.control.Button
        NotesTextArea                  matlab.ui.control.TextArea
        NotesTextAreaLabel             matlab.ui.control.Label
        MethodsDropDown                matlab.ui.control.DropDown
        ChooseROIDetectionMethodLabel  matlab.ui.control.Label
    end

    
    properties (Access = public)
        method_name % ROI method name
        selection_made = false;
    end
    

    methods (Access = public)
        
        function init(app)
            app.NameEditField.Visible = false;
            app.NameLabel.Visible = false;
            app.AddnewmethodButton.Visible = false;
            app.NotesTextArea.Editable = false;
            menu_items = [fetchn(sln_funcimage.ROIMethod,'method_name'); 'New...'];
            app.MethodsDropDown.Items = menu_items;
            app.NotesTextArea.Value = fetch1(sln_funcimage.ROIMethod & sprintf('method_name="%s"',app.MethodsDropDown.Value), 'notes');
            app.method_name = app.MethodsDropDown.Value;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.init();
        end

        % Value changed function: MethodsDropDown
        function MethodsDropDownValueChanged(app, event)
            value = app.MethodsDropDown.Value;
            app.method_name = value; 
            if strcmp(value,'New...')
                app.NameEditField.Visible = true;
                app.NameLabel.Visible = true;
                app.AddnewmethodButton.Visible = true;
                app.NotesTextArea.Value = '';
                app.NameEditField.Value = '';
                app.NotesTextArea.Editable = true;
            else
                app.NameEditField.Visible = false;
                app.NameLabel.Visible = false;
                app.AddnewmethodButton.Visible = false;
                app.NotesTextArea.Editable = false;
                app.NotesTextArea.Value = fetch1(sln_funcimage.ROIMethod & sprintf('method_name="%s"',value), 'notes');                
            end
        end

        % Button pushed function: AddnewmethodButton
        function AddnewmethodButtonPushed(app, event)
            notes = app.NotesTextArea.Value;
            key.notes = strcat(cell2mat(notes'));
            key.method_name = app.NameEditField.Value;
            insert(sln_funcimage.ROIMethod, key);
            app.MethodsDropDown.Value = app.MethodsDropDown.Items{1};
            app.init();
        end

        % Button pushed function: OKButton
        function OKButtonPushed(app, event)            
            app.ROIMethodChooserUIFigureCloseRequest();
        end

        % Close request function: ROIMethodChooserUIFigure
        function ROIMethodChooserUIFigureCloseRequest(app, event)
            app.method_name = app.MethodsDropDown.Value;
            app.selection_made = true;
            delete(app.ROIMethodChooserUIFigure);
            %delete(app)            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ROIMethodChooserUIFigure and hide until all components are created
            app.ROIMethodChooserUIFigure = uifigure('Visible', 'off');
            app.ROIMethodChooserUIFigure.Position = [100 100 546 295];
            app.ROIMethodChooserUIFigure.Name = 'ROI Method Chooser';
            app.ROIMethodChooserUIFigure.CloseRequestFcn = @(~,evt)ROIMethodChooserUIFigureCloseRequest(app,evt);

            % Create ChooseROIDetectionMethodLabel
            app.ChooseROIDetectionMethodLabel = uilabel(app.ROIMethodChooserUIFigure);
            app.ChooseROIDetectionMethodLabel.Position = [9 266 170 22];
            app.ChooseROIDetectionMethodLabel.Text = 'Choose ROI Detection Method';

            % Create MethodsDropDown
            app.MethodsDropDown = uidropdown(app.ROIMethodChooserUIFigure);
            app.MethodsDropDown.ValueChangedFcn = @(~,evt)MethodsDropDownValueChanged(app,evt);
            app.MethodsDropDown.Position = [9 237 311 22];

            % Create NotesTextAreaLabel
            app.NotesTextAreaLabel = uilabel(app.ROIMethodChooserUIFigure);
            app.NotesTextAreaLabel.HorizontalAlignment = 'center';
            app.NotesTextAreaLabel.Position = [417 266 37 22];
            app.NotesTextAreaLabel.Text = 'Notes';

            % Create NotesTextArea
            app.NotesTextArea = uitextarea(app.ROIMethodChooserUIFigure);
            app.NotesTextArea.Position = [339 120 193 137];

            % Create AddnewmethodButton
            app.AddnewmethodButton = uibutton(app.ROIMethodChooserUIFigure, 'push');
            app.AddnewmethodButton.ButtonPushedFcn = @(~,evt)AddnewmethodButtonPushed(app,evt);
            app.AddnewmethodButton.Position = [394 80 138 23];
            app.AddnewmethodButton.Text = 'Add new method';

            % Create NameEditField
            app.NameEditField = uieditfield(app.ROIMethodChooserUIFigure, 'text');
            app.NameEditField.Position = [61 80 303 22];

            % Create NameLabel
            app.NameLabel = uilabel(app.ROIMethodChooserUIFigure);
            app.NameLabel.Position = [9 80 37 22];
            app.NameLabel.Text = 'Name';

            % Create OKButton
            app.OKButton = uibutton(app.ROIMethodChooserUIFigure, 'push');
            app.OKButton.ButtonPushedFcn = @(~,evt)OKButtonPushed(app,evt);
            app.OKButton.Position = [433 11 100 23];
            app.OKButton.Text = 'OK';

            % Show the figure after all components are created
            app.ROIMethodChooserUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ROI_method_chooser_dlg

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            %registerApp(app, app.ROIMethodChooserUIFigure)

            % Execute the startup function
            app.startupFcn()

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ROIMethodChooserUIFigure)
        end
    end
end