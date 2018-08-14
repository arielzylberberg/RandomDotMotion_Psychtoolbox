classdef EyeTrackerClass < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dummymode = 0
        edfFile = 'DEMO'
        el
        eye_used
        
        x_last
        y_last
        p_last
        t_last
        
    end
    
    methods
        function obj = EyeTrackerClass()
            
%             if ~Eyelink('IsConnected')
%                 obj.dummymode = 1;
%             end
        end
        
        function setPars(obj,varargin)
            for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
            if obj.dummymode == 1
                ShowCursor();
            end
        end
        
        function trialInfo(obj)
            %what info to save after each trial
        end
        
        function out = sessionInfo(obj)
            %what info to save for each session
            out.dummymode = obj.dummymode;
            out.el = obj.el;
            out.eye_used = obj.eye_used;
            
        end
        
        
        function Message(obj,str)
            Eyelink('message', str);
        end
        
        function setupEyetracker(obj,screenInfo)
            %%%%%%%%%%
            % STEP 2 %
            %%%%%%%%%%
            window = screenInfo.curWindow;
            
            
            [winWidth, winHeight] = WindowSize(window);
            
            %%%%%%%%%%
            % STEP 3 %
            %%%%%%%%%%
            
            % Provide Eyelink with details about the graphics environment
            % and perform some initializations. The information is returned
            % in a structure that also contains useful defaults
            % and control codes (e.g. tracker state bit and Eyelink key values).
            
            el=EyelinkInitDefaults(window);
            
            % We are changing calibration to a black background with white targets,
            % no sound and smaller targets
            el.backgroundcolour = BlackIndex(el.window);
            el.msgfontcolour  = WhiteIndex(el.window);
            el.imgtitlecolour = WhiteIndex(el.window);
            el.targetbeep = 0;
            el.calibrationtargetcolour = WhiteIndex(el.window);
            
            % for lower resolutions you might have to play around with these values
            % a little. If you would like to draw larger targets on lower res
            % settings please edit PsychEyelinkDispatchCallback.m and see comments
            % in the EyelinkDrawCalibrationTarget function
            el.calibrationtargetsize= 1;
            el.calibrationtargetwidth=0.5;
            % call this function for changes to the calibration structure to take
            % affect
            el.devicenumber = -1;
            EyelinkUpdateDefaults(el);
            
            
            %%%%%%%%%%
            % STEP 4 %
            %%%%%%%%%%
            
            % Initialization of the connection with the Eyelink Gazetracker.
            % exit program if this fails.
            
            if ~EyelinkInit(obj.dummymode)
                fprintf('Eyelink Init aborted.\n');
                cleanup;  % cleanup function
                return;
            end
            
            % open file to record data to
            i = Eyelink('Openfile', obj.edfFile);
            if i~=0
                fprintf('Cannot create EDF file ''%s'' ', obj.edfFile);
                cleanup;
                return;
            end
            
            % make sure we're still connected.
            if Eyelink('IsConnected')~=1 && ~obj.dummymode
                cleanup;
                return;
            end;
            
            %%%%%%%%%%
            % STEP 5 %
            %%%%%%%%%%
            
            % SET UP TRACKER CONFIGURATION
            % Setting the proper recording resolution, proper calibration type,
            % as well as the data file content;
            Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox - ariel zylberberg''');
            
            % This command is crucial to map the gaze positions from the tracker to
            % screen pixel positions to determine fixation
            Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, winWidth-1, winHeight-1);
            
            Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, winWidth-1, winHeight-1);
            % set calibration type.
            Eyelink('command', 'calibration_type = HV9');
            Eyelink('command', 'generate_default_targets = YES');
            % set parser (conservative saccade thresholds)
            Eyelink('command', 'saccade_velocity_threshold = 35');
            Eyelink('command', 'saccade_acceleration_threshold = 9500');
            % set EDF file contents
            % 5.1 retrieve tracker version and tracker software version
            [v,vs] = Eyelink('GetTrackerVersion');
            fprintf('Running experiment on a ''%s'' tracker.\n', vs );
            vsn = regexp(vs,'\d','match');
            
            if v ==3 && str2double(vsn{1}) == 4 % if EL 1000 and tracker version 4.xx
                
                % remote mode possible add HTARGET ( head target)
                Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
                Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
                % set link data (used for gaze cursor)
                Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
                Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT,HTARGET');
            else
                Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
                Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
                % set link data (used for gaze cursor)
                Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
                Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
            end
            
            % calibration/drift correction target
            Eyelink('command', 'button_function 5 "accept_target_fixation"');
            
            %%%%%%%%%%
            % STEP 6 %
            %%%%%%%%%%
             
%             if ~obj.dummymode
%                 % Hide the mouse cursor and setup the eye calibration window
%                 Screen('HideCursorHelper', window);
%             end
            % enter Eyetracker camera setup mode, calibration and validation
            EyelinkDoTrackerSetup(el);
            
            
            % supuestamente, hacer al principio de cada trial. Ver para
            % que sirve !!
            %             EyelinkDoDriftCorrection(el);
            
            obj.el = el;
            
            % STEP 7.3
            % start recording eye position (preceded by a short pause so that
            % the tracker can finish the mode transition)
            % The paramerters for the 'StartRecording' call controls the
            % file_samples, file_events, link_samples, link_events availability
            
            
            Eyelink('Command', 'set_idle_mode');
            WaitSecs(0.05);
            Eyelink('StartRecording');
            obj.eye_used = Eyelink('EyeAvailable');
            if obj.eye_used == 2
                obj.eye_used = 0; % if binocular use left
            end
        end
        
        function doCalibration(obj)
            %hay otra forma mejor?
            Eyelink('StopRecording');
            EyelinkDoTrackerSetup(obj.el);
            Eyelink('StartRecording');%empieze de cero ???
        end
        
        function doDriftCorrection(obj)
            Eyelink('StopRecording');
            EyelinkDoDriftCorrect(obj.el);
            Eyelink('StartRecording');%empieze de cero ???
        end
        
        function [mx,my,pa,mt,newSample] = getEyedata(obj)
            
            newSample = false;
            mx = obj.x_last;
            my = obj.y_last;
            pa = obj.p_last;
            mt = obj.t_last;
            if obj.dummymode==0
                error = Eyelink('CheckRecording');
                if(error~=0)
                    return;
                end
                
                if Eyelink('NewFloatSampleAvailable') > 0
                    % get the sample in the form of an event structure
                    evt = Eyelink('NewestFloatSample');
                    if obj.eye_used ~= -1 % do we know which eye to use yet?
                        % if we do, get current gaze position from sample
                        x = evt.gx(obj.eye_used+1); % +1 as we're accessing MATLAB array
                        y = evt.gy(obj.eye_used+1);
                        pa = evt.pa(obj.eye_used+1);
                        t = GetSecs();
                        % do we have valid data and is the pupil visible?
                        if x~=obj.el.MISSING_DATA && y~=obj.el.MISSING_DATA && evt.pa(obj.eye_used+1)>0
                            mx = x;
                            my = y;
                            newSample = true;
                            mt = t;
                        end
                    end
                end
            else
                
                % Query current mouse cursor position (our "pseudo-eyetracker") -
                % (mx,my) is our gaze position.
                [mx, my] = GetMouse(); %#ok<*NASGU>
                newSample = true;
            end
            obj.x_last = mx;
            obj.y_last = my;
            obj.p_last = pa;
            obj.t_last = mt;
            
        end
        
        function ShowEyePosition(obj,screenInfo,type)

            if nargin<3
                type='dot';
            end
            
            if isequal(type,'mask')
                w = screenInfo.curWindow;

                white=WhiteIndex(w);
                black=BlackIndex(w);
                gray=(white+black)/2;

                ms=20;
                transLayer=2;
                [x,y]=meshgrid(-ms:ms, -ms:ms);
                maskblob = uint8(ones(2*ms+1, 2*ms+1, transLayer) * gray);
                size(maskblob);

                % Layer 2 (Transparency aka Alpha) is filled with gaussian transparency
                % mask.
                xsd=ms/2.0;
                ysd=ms/2.0;
                maskblob(:,:,transLayer)=uint8(exp(-((x/xsd).^2)-((y/ysd).^2))*255);

                % Build a single transparency mask texture
                masktex=Screen('MakeTexture', w, maskblob);
    %             mRect=Screen('Rect', masktex);
                
                %[mx,my] = obj.GetMousePosition(w);
                [mx,my] = obj.getEyedata();
                %[mx,my] = GetMouse(); 

                myrect = [mx-ms my-ms mx+ms+1 my+ms+1]; % center dRect on current mouseposition
    %             myrect = CenterRect(rect,fixedRect)
                %Screen('BlendFunction', curWindow, GL_ONE, GL_ZERO);
                Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('DrawTexture', w, masktex, [], myrect);
                
            elseif isequal(type,'dot')
                radio = 3;
                color = [255 0 0];
%                 color = [0 0 255];
                % [mx,my] = GetMouse(); 
                [mx,my] = obj.getEyedata();
                rect = [mx-radio my-radio mx+radio my+radio];
                Screen('FillOval',screenInfo.curWindow,color,rect);
                
            end
            
            
%             w = screenInfo.curWindow;
%             
%             white=WhiteIndex(w);
%             black=BlackIndex(w);
%             gray=(white+black)/2;
%             
%             ms=50;
%             transLayer=2;
%             [x,y]=meshgrid(-ms:ms, -ms:ms);
%             maskblob = uint8(ones(2*ms+1, 2*ms+1, transLayer) * gray);
%             size(maskblob);
% 
%             % Layer 2 (Transparency aka Alpha) is filled with gaussian transparency
%             % mask.
%             xsd=ms/2.0;
%             ysd=ms/2.0;
%             maskblob(:,:,transLayer)=uint8(exp(-((x/xsd).^2)-((y/ysd).^2))*255);
%             
%             
%             % Build a single transparency mask texture
%             masktex=Screen('MakeTexture', w, maskblob);
%     
%             
%             [mx,my] = obj.getEyedata();
%             myrect = [mx-ms my-ms mx+ms+1 my+ms+1]; % center dRect on current mouseposition
%             Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
%             Screen('DrawTexture', w, masktex, [], myrect);
            
            
            
        end
        
        
        function StopAndGetFile(obj,newfilename)
            
            Eyelink('StopRecording');
            
            Eyelink('Command', 'set_idle_mode');
            
            Eyelink('CloseFile');
            
            % download data file
            try
                fprintf('Receiving data file ''%s''\n', obj.edfFile );
                status=Eyelink('ReceiveFile');
                if status > 0
                    fprintf('ReceiveFile status %d\n', status);
                end
                if 2==exist(obj.edfFile, 'file')
                    fprintf('Data file ''%s'' can be found in ''%s''\n', obj.edfFile, pwd );
                    
                    %rename file:
                    system(['mv ',obj.edfFile,'.edf ',newfilename,'.edf'])
                    
                end
            catch %#ok<*CTCH>
                fprintf('Problem receiving data file ''%s''\n', obj.edfFile );
            end
            
            
            %%%%%%%%%%
            % STEP 9 %
            %%%%%%%%%%
            
            % run cleanup function (close the eye tracker and window).
            cleanup;
            
        end
        
        
    end
    
end


function cleanup
% Shutdown Eyelink:
Eyelink('Shutdown');
% Screen('CloseAll');
end







