classdef confidenceAnnulusClass < handle
    properties
        radio_deg = 10; 
        radio_px
        startAngle = -60; %from horizontal
        arcAngle = 120; %from start angle, clockwise
        color_ini = [0 255 0];
        color_fin = [255 0 0];

        puntos
%         marker_color = [255/2 255/2 255];
        marker_color = [255 204 77];
        marker_radio = 7;
        mouse_acceptance_dist = 50;
        
        traj
        
        choice
        conf
        RT
        
        show_text = false
        
    end
    
    methods
        function obj = confidenceBarClass()
            
        end
        
        function setPars(obj,varargin)
           for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end 
        end
        
        function prepare(obj,screenInfo)
            
            cx = screenInfo.center(1);
            cy = screenInfo.center(2);
            
            obj.radio_px = deg2pix(obj.radio_deg,screenInfo);
            
            npuntos = 200;
            
            startAngle  = obj.startAngle;
            arcAngle    = obj.arcAngle;
            
            x = nan(npuntos,1);
            y = nan(npuntos,1);
            for i=1:npuntos
                w = (i-1)/(npuntos-1);
                angle = startAngle + arcAngle*w;
                x(i) = cos(angle*(2*pi)/360)*obj.radio_px;
                y(i) = sin(angle*(2*pi)/360)*obj.radio_px;
                color(i,:) = obj.color_ini*(1-w) + obj.color_fin*w;
            end
            
            obj.puntos(1).x = x+cx;
            obj.puntos(1).y = y+cy;
            obj.puntos(1).color = color;
            
            obj.puntos(2).x = -x+cx;
            obj.puntos(2).y = y+cy;
            obj.puntos(2).color = color;
            
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
                Screen('DrawDots', curWindow, xy,5,color',[],1);
            end
%             Screen('FrameArc',curWindow,obj.color,rect,startAngle,arcAngle,1);
%             Screen('FrameArc',curWindow,obj.color,rect,startAngle+180,arcAngle,1);
        end
        
        
        function [curve_id,min_dist,xmin,ymin] = get_closer_point(obj,x,y)
            
            min_dist  = nan(2,1);
            min_index = nan(2,1);
            xmin = nan(2,1);
            ymin = nan(2,1);
            for i=1:2
                xy = [obj.puntos(i).x';obj.puntos(i).y'];
                distance = sqrt(sum(bsxfun(@minus,xy,[x;y]).^2));
                min_dist(i) = min(distance);
                min_index(i) = find(distance==min_dist(i),1);
                xmin(i) = xy(1,min_index(i));
                ymin(i) = xy(2,min_index(i));
            end
            curve_id = find(min_dist==min(min_dist),1);
            min_dist = min_dist(curve_id);
            xmin = xmin(curve_id);
            ymin = ymin(curve_id);
            
        end
        
        function [in_region,curve_id,min_dist,xmin,ymin,buttons] = inAcceptanceRegion(obj,tini,screenInfo,Mouse)
            
            in_region = false;
            
            % [mx,my,buttons] = Mouse.GetMousePosition('center',screenInfo.center);
            [mx,my,buttons] = Mouse.GetMousePosition(screenInfo.curWindow);
            % guardar
            if isempty(obj.traj) || ...
                    (obj.traj(end,2)~=mx && obj.traj(end,3)~=my)
                obj.traj = [obj.traj; GetSecs()-tini mx my];
            end
            
            %ver si el trial termina
            [curve_id,min_dist,xmin,ymin] = obj.get_closer_point(mx,my);
            
            if min_dist < obj.mouse_acceptance_dist || ...
                    (sqrt((mx-screenInfo.center(1))^2 + (my-screenInfo.center(2))^2)>obj.radio_px)
                radio = obj.marker_radio;
                rect = [xmin-radio, ymin-radio, xmin+radio, ymin+radio];
                Screen('FillOval',screenInfo.curWindow,obj.marker_color,rect);
                
                if obj.show_text
                    delta_x = -20;
                    delta_y = 20;
                    
                    % for text
                    mx = xmin - screenInfo.center(1);
                    my = ymin - screenInfo.center(2);
                    
                    angulo = 360*atan2(-my,abs(mx))/(2*pi);
                    angulo = 50 + 50 * (angulo - obj.startAngle)/obj.arcAngle;
                    angulo = round(angulo);
                    text = [num2str(angulo),'%'];
                    Screen('DrawText', screenInfo.curWindow, text, xmin+delta_x,ymin+delta_y,[255,255,255]);

                end
                
                in_region = true;
                
%                 if any(buttons)
%                     InAcceptanceRegion = true;
%                 end
            end
                
%                 if abs(atan(my/mx))<abs(obj.startAngle)*(2*pi/360) && any(buttons)
%                     respGiven = true;
%                 end
%                 
%                 %restringir a la region
%                 angulo = atan2(my,mx);
%                 x = obj.radio_px*cos(angulo);
%                 y = obj.radio_px*sin(angulo);
%                 %deberia interpolar el tiempo !!!
%                 obj.traj(end,2) = x;
%                 obj.traj(end,3) = y;
% %                 [x,y] = RestrictToRegion(mx,my,
                

            
        end
        
        function [choice,conf] = getChoiceConfidenceRT(obj,Tx,Ty)
            
%             Tx = obj.traj(end,2);
%             Ty = obj.traj(end,3);
            
            if Tx>0
                choice = 1;
            else
                choice = 2;
            end
            
            
            maxY = sin(2*pi/360*obj.startAngle)*obj.radio_px;
            minY = sin(2*pi/360*(obj.startAngle+obj.arcAngle))*obj.radio_px;
            conf = (Ty-minY)/(maxY-minY);
%             RT = obj.traj(end,1);
            
            obj.choice = choice;
            obj.conf = conf;
            
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