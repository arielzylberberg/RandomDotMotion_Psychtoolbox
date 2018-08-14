classdef MouseClass < handle
    properties
    end
    
    methods
        function obj = MouseClass()
        end
        
        function centerMouse(obj,screenInfo)
            SetMouse(screenInfo.center(1),screenInfo.center(2),screenInfo.curWindow);
        end
        
        function SetMousePosition(obj,x,y,curWindow)
            % Working? needs rounding??
            
            if isempty(x)
                [x,~] = obj.GetMousePosition(curWindow);
            elseif isempty(y)
                [~,y] = obj.GetMousePosition(curWindow);
            end
            SetMouse(x,y,curWindow);
            
            
            
        end
        
        function [mx,my,buttons] = GetMousePosition(obj,curWindow,varargin)
            center = [0 0];
            for i=1:length(varargin)
                if isequal(varargin{i},'center')
                    center = varargin{i+1};
                end
            end
            [mx,my,buttons] = GetMouse(curWindow); 
            mx = mx - center(1);
            my = my - center(2);
            
        end
        
        function Hide(obj,screenInfo)
            HideCursor(screenInfo.curWindow);
        end
        
        function Show(obj,screenInfo)
            type = 0;
            ShowCursor(type,screenInfo.curWindow);
        end
        
        function out = sessionInfo(obj)
            out = [];
        end
        
        
        function ShowMousePosition(obj,screenInfo,type)
            
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
                
                [mx,my] = obj.GetMousePosition(w);
                %[mx,my] = GetMouse(); 

                myrect = [mx-ms my-ms mx+ms+1 my+ms+1]; % center dRect on current mouseposition
    %             myrect = CenterRect(rect,fixedRect)
                %Screen('BlendFunction', curWindow, GL_ONE, GL_ZERO);
                Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('DrawTexture', w, masktex, [], myrect);
                
            elseif isequal(type,'dot')
                radio = 3;
                color = [255/2 255/2 255];
%                 color = [0 0 255];
                [mx,my] = GetMouse(); 
                rect = [mx-radio my-radio mx+radio my+radio];
                Screen('FillOval',screenInfo.curWindow,color,rect);
                
            end
            
        end
    end
end
