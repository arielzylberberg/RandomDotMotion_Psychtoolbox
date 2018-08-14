classdef sliderClass < handle
    properties
        initial_pos
        color_linea = [255 255 255]*0.4;
        color_fondo  = [0 0 0];
        dot_type     = 1;
        
        dot_color   = 1.2*[76, 40, 130];
        colorGrabOff = .7*[255 255 255];
        colorGrabOn  = .7*[255 0 0];
        
        dotDiameterDeg = 0.2; % en grados
        
        horizontal = true
        
        % limits, in pixels
        Xlow           = 200
        Xhigh          = 600
        Yhigh          = 200
        Ylow           = 200
        
        % for the size of the arrowhead
        Lx_px = 20;
        Ly_px = 20;
        grab_radio_px = 25;
        
        % just to transfer from one frame to the next
        isGrabbed
        deltax
        deltay
        colorGrab
        
        hasBeenGrabbed
        posx
        posy
        mousetraj
        sliderpos
        
    end
    
    methods
        
        function obj = sliderClass()
        end
        
        function setPars(obj,varargin)
            for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        function prepare(obj)
        end
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
        end
        
        function ForTrialData = trialInfo(obj)
            ForTrialData.mousetraj = obj.mousetraj;
            ForTrialData.sliderpos = obj.sliderpos;
            ForTrialData.posx = obj.posx;
            ForTrialData.posy = obj.posy;
        end
        
        function [px,py,slpos]= getResp()
            px = obj.posx;
            py = obj.posy;
            slpos = obj.sliderpos;
            % just return the outputs
        end
        
        function prepare_trial(obj,posx,posy)
            
            if nargin==1 % use what is there already
                posx = obj.posx;
                posy = obj.posy;
            end
            
            %reset traj
            obj.mousetraj = [];
            obj.sliderpos = [];
            obj.posx = posx;
            obj.posy = posy;
            obj.isGrabbed  = false;
            obj.colorGrab  = obj.colorGrabOff;
            obj.deltax = [];
            obj.deltay = [];
            obj.hasBeenGrabbed = false;
            
        end
        
        function draw(obj,screenInfo)
            
            theWindow = screenInfo.curWindow;
            
            %             iniPos = 0.5; % position of the left slider
            
            ppd     = screenInfo.ppd;
            dotSize = obj.dotDiameterDeg*ppd;
            
            %%
            
            
            [ex,ey,buttons] = GetMouse(theWindow);
            
            if obj.horizontal
                pointList = [-obj.Lx_px/2 -obj.Ly_px;
                    0      0;
                    obj.Lx_px/2  -obj.Ly_px;
                    -obj.Lx_px/2 -obj.Ly_px];
            else
                pointList = [obj.Lx_px -obj.Ly_px/2;
                    obj.Lx_px  obj.Ly_px/2;
                    0      0;
                    obj.Lx_px -obj.Ly_px/2];
            end
            pointList  = bsxfun(@plus,pointList,+[obj.posx obj.posy]);
            Screen('FillPoly', theWindow, obj.colorGrab, pointList);
            
            
            % slideHandle.cx = 1/2*obj.Lx_px + obj.posx;
            slideHandle.cx = obj.posx;
            slideHandle.cy = obj.posy;
            
            
            %                 colorGrab  = obj.colorGrabOff;
            
            if not(any(buttons))
                obj.isGrabbed  = false;
            end
            
            if ((sqrt((ex-slideHandle.cx).^2+(ey-slideHandle.cy).^2) < obj.grab_radio_px) && any(buttons)) ...
                    || obj.isGrabbed
                
                if not(obj.isGrabbed) % first time
                    obj.deltay     = ey-obj.posy;
                    obj.deltax     = ex-obj.posx;
                    obj.isGrabbed = true;
                    obj.hasBeenGrabbed = true; %never turns backt to false
                end
                
                obj.colorGrab = obj.colorGrabOn;% change the color
                
                obj.posy      = ey - obj.deltay;
                obj.posx      = ex - obj.deltax;
                
            else
                obj.colorGrab = obj.colorGrabOff;% change the color
            end
            
            [ex,ey,buttons] = GetMouse(theWindow);
            
            % constraint movement
            
            if obj.posy>obj.Yhigh
                obj.posy = obj.Yhigh;
            elseif obj.posy<obj.Ylow
                obj.posy = obj.Ylow;
            end
            if obj.posx<obj.Xlow
                obj.posx = obj.Xlow;
            elseif obj.posx>obj.Xhigh
                obj.posx = obj.Xhigh;
            end
            
            Screen('DrawDots', theWindow, [ex ey], dotSize, obj.dot_color,[0 0],obj.dot_type);
            
            % save only if there was a change in mouse position
            if not(isempty(obj.mousetraj)) && (ex~=obj.mousetraj(end,2) || (ey~=obj.mousetraj(end,3))) || ...
                    isempty(obj.mousetraj)
                
                obj.mousetraj = [obj.mousetraj; ...
                    GetSecs ex ey obj.posx obj.posy];
            end
            
            %                 disp([obj.posx,obj.posy])
            %             end
            
            if obj.horizontal
                obj.sliderpos = (obj.posx-obj.Xlow)/(obj.Xhigh-obj.Xlow);
            else
                obj.sliderpos = (obj.posy-obj.Ylow)/(obj.Yhigh-obj.Ylow);
            end
            
            
        end
        
    end
end
