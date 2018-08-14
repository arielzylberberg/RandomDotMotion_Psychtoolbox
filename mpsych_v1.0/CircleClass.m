classdef CircleClass < handle
    properties
        radio
        rect
        position
        color
    end
    
    methods
        
        function obj = CircleClass(x,y,radio,color)
            obj.color = color;
            obj.position.x = x;
            obj.position.y = y;
            obj.position.radio = radio;
            obj.rect = [x-radio y-radio x+radio y+radio];
            
        end
        
        function setPars(obj,varargin)
            for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        function [x, y] = getCenter(obj)
            x = obj.position.x;
            y = obj.position.y;
        end
        
        function changePosition(obj,x,y)
            obj.position.x = x;
            obj.position.y = y;
            radio = obj.position.radio;
            obj.rect = [x-radio, y-radio, x+radio, y+radio];
        end
        
        function d = euclideanDistance(obj,xm,ym)
            [x,y] = obj.getCenter();
            d = sqrt((x-xm)^2+(y-ym)^2);
            
        end
        
        function draw(obj,curWindow)
            Screen('FillOval',curWindow,obj.color,obj.rect);
        end
    end
end