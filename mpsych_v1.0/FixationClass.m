classdef FixationClass < handle
    properties
        fix
        
        %         typeInt = 2;
        %         minInt = 0.3;
        %         maxInt  = 1;
        %         meanInt = .5;
        
        %         stimdur
        fix_accept_radius_deg = 3 %deg
        
    end
    methods
        function obj = FixationClass(x,y,radio,color)
            obj.fix.dat = CircleClass(x,y,radio,color);
        end
        
        %         function sampleDuration(obj)
        %             obj.stimdur = makeInterval(obj.typeInt,obj.minInt,obj.maxInt,obj.meanInt);
        %         end
        
        function ForTrialData = trialInfo(obj)
            %             ForTrialData.dur = obj.stimdur;
            ForTrialData = [];
        end
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
        end
        
        function setPars(obj,varargin)
            for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        function cleanForNextTrial(obj)
        end
        
        function draw(obj,screenInfo)
            obj.fix.dat.draw(screenInfo.curWindow);
        end
        
        function f = fixAcquired(obj,screenInfo,Eye,Key,Mouse)
            f = false;
            if Eye.dummymode==0
                [mx,my,pa,mt,newSample] = Eye.getEyedata();
                rdeg = obj.fix_accept_radius_deg;
                r = rdeg * screenInfo.ppd;
                d = obj.fix.dat.euclideanDistance(mx,my);
                if d<=r
                    f = true;
                else
                    f = false;
                end
                if Key.pressed() && all(ismember(Key.abort_key,Key.last_pressed_key))
                    sca; %mejorar
                end
                
            else
                % simulo adquisicion con keypress
                if Key.pressed()
                    if Key.last_pressed_key == Key.fixation_key
                        f = true;
                    elseif all(ismember(Key.abort_key,Key.last_pressed_key))
                        sca; %mejorar
                    end
                end
                %                 Mouse.ShowMousePosition(screenInfo);
            end
            
        end
        
        function f = lostFixation(obj,screenInfo,Eye,Key,Mouse)
            
            if Eye.dummymode==0
                f = ~obj.fixAcquired(screenInfo,Eye,Key,Mouse);
            else
                f = false;
            end
            
        end
        
        
    end
end

