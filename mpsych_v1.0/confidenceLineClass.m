classdef confidenceLineClass < handle
    properties
        
        ini_deg = 0;
        fin_deg = 12;
        ini_px
        fin_px
        color_ini = 0.3*[1 1 1]*255
        color_fin = [1 1 1]*255
        point_size = 5
        ypos_px = 0 
        
        puntos
        color
        
        traj
        
        choice
        conf
        RT
        
        vertical = false
        
    end
    
    methods
        function obj = confidenceLineClass(varargin)
            obj.setPars(varargin{:});
        end
        
        function setPars(obj,varargin)
            for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        function prepare(obj,screenInfo)
            
            cx = screenInfo.center(1);
            cy = screenInfo.center(2);
            
            obj.ini_px = deg2pix(obj.ini_deg,screenInfo);
            obj.fin_px = deg2pix(obj.fin_deg,screenInfo);
            
            npuntos = 200;
            
            x = nan(npuntos,1);
            y = nan(npuntos,1);
            for i=1:npuntos
                w = (i-1)/(npuntos-1);
                xx = obj.ini_px + w*(obj.fin_px-obj.ini_px);
                if ~obj.vertical
                    x(i) = xx;
                    y(i) = obj.ypos_px;
                else
                    y(i) = xx;
                    x(i) = obj.ypos_px;
                end
                color(i,:) = obj.color_ini*(1-w) + obj.color_fin*w;
            end
            
            if ~obj.vertical
                obj.puntos(1).x = x+cx;
                obj.puntos(1).y = y+cy;
                obj.puntos(2).x = -x+cx;
                obj.puntos(2).y = y+cy;
            else
                obj.puntos(1).x = x+cx;
                obj.puntos(1).y = y+cy;
                obj.puntos(2).x = x+cx;
                obj.puntos(2).y = -y+cy;
            end
            obj.puntos(1).color = color;
            obj.puntos(2).color = color;
            
        end
        
        function add_text(obj,screenInfo,xrel,ypix,str)
            
            cx = screenInfo.center(1);
%             cy = screenInfo.center(2);
            
            if isnan(xrel)
                xx = 'center'; 
            else    
                xx = cx + obj.ini_px+xrel*(obj.fin_px-obj.ini_px);
            end
            [nx, ny, bbox] = DrawFormattedText(screenInfo.curWindow, str, ...
                xx, ypix,  [255,255,255]);
            
        end
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
        end
        
        function ForTrialData = trialInfo(obj)
            ForTrialData.traj = obj.traj;
        end
        
        function prepare_trial(obj)
            %reset traj
            obj.traj = [];
            obj.choice = nan;
            obj.conf = nan;
        end
        
        function draw(obj,screenInfo)
            
            Screen('BlendFunction', screenInfo.curWindow, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            curWindow   = screenInfo.curWindow;
            for i=1:2
                xy = [obj.puntos(i).x';obj.puntos(i).y'];
                color = obj.puntos(i).color;
                Screen('DrawDots', curWindow, xy,obj.point_size,color',[],1);
            end
%             Screen('FrameArc',curWindow,obj.color,rect,startAngle,arcAngle,1);
%             Screen('FrameArc',curWindow,obj.color,rect,startAngle+180,arcAngle,1);
        end
        
        function respGiven = gotResp(obj,tini,screenInfo,Mouse)
            
            respGiven = false;
            
            [mx,my] = Mouse.GetMousePosition(screenInfo.curWindow,'center',screenInfo.center);
            
            % guardar
            if isempty(obj.traj) || ...
                    (obj.traj(end,2)~=mx && obj.traj(end,3)~=my)
                obj.traj = [obj.traj; GetSecs()-tini mx my];
                
            end
            
            region.type = 'rect';
            delta = 10;%tolerance for response
            miniX = min(obj.puntos(2).x);
            maxiX = max(obj.puntos(1).x);
            region.spec = [miniX-screenInfo.center(1) obj.ypos_px-delta maxiX-screenInfo.center(1) obj.ypos_px+delta];
            if obj.vertical
                pos = [my mx];
            else
                pos = [mx my];
            end
            inside = isInsideRegion(pos, region);
            
            %ver si el trial termina
            if (inside)
                respGiven = true;
            end
            
        end
        
        function [choice,conf,signed] = getChoiceConfidenceRT(obj,Tx,Ty)
            
            
            if obj.vertical
%                 Txtemp = Tx;
                Tx = Ty;
%                 Ty = Txtemp;
            end
            
            if Tx>0
                choice = 1;
            else
                choice = 2;
            end
            
            minX = obj.ini_px;
            maxX = obj.fin_px;
            conf = (abs(Tx)-minX)/(maxX-minX);
%             RT = obj.traj(end,1);
            

            obj.choice = choice;
            obj.conf = conf;
            
            signed = conf * sign(Tx);
            
%             obj.RT = RT;
        end
        
        
        
        function ShowTrajPosition(obj,screenInfo,type)
            
            mx = obj.traj(end,2)+screenInfo.center(1);
            my = obj.traj(end,3)+screenInfo.center(2);
            if isequal(type,'mask')
                w = screenInfo.curWindow;

                white=WhiteIndex(w);
                black=BlackIndex(w);
                gray=(white+black)/2;

                ms=50;
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

%                 [mx,my] = GetMouse(); 

                myrect = [mx-ms my-ms mx+ms+1 my+ms+1]; % center dRect on current mouseposition
    %             myrect = CenterRect(rect,fixedRect)
                %Screen('BlendFunction', curWindow, GL_ONE, GL_ZERO);
                Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('DrawTexture', w, masktex, [], myrect);
                
            elseif isequal(type,'dot')
                radio = 3;
                color = [255/2 255/2 255];
%                 color = [0 0 255];
%                 [mx,my] = GetMouse(); 
                rect = [mx-radio my-radio mx+radio my+radio];
                Screen('FillOval',screenInfo.curWindow,color,rect);
                
            end
            
        end
        
    end
end