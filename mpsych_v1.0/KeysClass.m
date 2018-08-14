classdef KeysClass < handle
    properties
        targ
        abort_key = [KbName('LeftAlt') KbName('ESCAPE')];
        eyecalibrate_key = [KbName('LeftAlt') KbName('c')];
        pause_key = KbName('p')
        resume_key = KbName('r')
        space_key = KbName('space')
        fixation_key = KbName('space');
        responseReady_key = KbName('space');
        
        %calibrate...
        abort = false
        calibrate_eye = false
        pause = false
        resume = false
        space = false
        
        last_pressed_key
        last_pressed_time
    end
    
    methods
        function obj = KeysClass()
        end
        
        function cleanForNextTrial(obj)
            obj.last_pressed_key = [];
            obj.last_pressed_time = [];
            obj.abort = false;
            obj.calibrate_eye = false;
            obj.pause = false;
            obj.resume = false;
            obj.space = false;
        end
        
        function wait_and_clean(obj)
            while KbCheck(-1);end
            obj.last_pressed_key = [];
            obj.last_pressed_time = [];
            obj.abort = false;
            obj.calibrate_eye = false;
            obj.pause = false;
            obj.resume = false;
            obj.space = false;
        end
        
%         function asocToTarget(obj,tarId,key)
%             obj.targ{tarId} = KbName(key);
%         end
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
        end
        
        
        function boolKeyPressed = pressed(obj)
            obj.last_pressed_key  = [];
            obj.last_pressed_time = [];
            boolKeyPressed = false;
            % Check the state of the keyboard.
            [keyIsDown, seconds, keyCode] = KbCheck(-1);
            if keyIsDown
                obj.last_pressed_time = seconds;
                obj.last_pressed_key = find(keyCode);
                boolKeyPressed = true;
                if all(keyCode(obj.abort_key))
                    obj.abort = true;
                elseif all(keyCode(obj.eyecalibrate_key))
                    obj.calibrate_eye = true;
                elseif all(keyCode(obj.pause_key))
                    obj.pause = true;
                elseif all(keyCode(obj.resume_key))
                    obj.resume = true;
                elseif all(keyCode(obj.space_key))
                    obj.space = true;
                end
            end
        end
        
    end
end

