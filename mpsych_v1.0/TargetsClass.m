classdef TargetsClass < handle
    properties
        ntarg = 0
        targ
        keys
        selTar
        timeSelTar
        colorOver = nan;
        
        tar_accept_radius_deg = 5 %deg
        allow_eye_responses = 1
        
    end
    methods
        function obj = TargetsClass()
        end
        
        function add(obj,x,y,radio,color)
            for i=1:length(x)
                obj.ntarg = obj.ntarg + 1;
                obj.targ(obj.ntarg).dat = CircleClass(x(i),y(i),radio(i),color(i,:));
                obj.targ(obj.ntarg).visible = true;
            end
        end
        
        function setPars(obj,varargin)
            for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        function setVisible(obj,tarId,visible_flag)
            for i=1:length(tarId)
                obj.targ(tarId(i)).visible = visible_flag;
            end
        end
        
        function changePosition(obj,tarId,x,y)
            obj.targ(tarId).dat.changePosition(x,y);
        end
        
        function cleanForNextTrial(obj)
            obj.selTar = [];
            obj.timeSelTar = [];
        end
        
        function asocToKey(obj,tarId,key)
            obj.keys{tarId} = KbName(key);
        end
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
        end
        
        function draw(obj,screenInfo)
            for i=1:obj.ntarg
                if (obj.targ(i).visible)
                    obj.targ(i).dat.draw(screenInfo.curWindow);
                end
            end
        end
        
        function boolTarSelected = tarSelected(obj,screenInfo,Eye,Key)
            boolTarSelected = false;
            obj.selTar = [];
            
            
            if obj.allow_eye_responses
                %check for eye response
                [mx,my,pa,mt,newSample] = Eye.getEyedata();
                rdeg = obj.tar_accept_radius_deg;
                r = rdeg * screenInfo.ppd;
                dv = nan(obj.ntarg,1);
                for i=1:obj.ntarg
                    ec = obj.targ(i).dat.euclideanDistance(mx,my);
                    if isscalar(ec)
                        dv(i) = ec;
                    end
                end
                
                [d,i] = min(dv);
                if d<=r
                    boolTarSelected = true;
                    obj.selTar = i;
                    obj.timeSelTar = GetSecs();
                end
            end
            
%             %key response
            if Key.pressed()
                for i=1:obj.ntarg
                    if ~isempty(obj.keys) && Key.last_pressed_key==obj.keys{i}
                        obj.selTar = i;
                        boolTarSelected = true;
                    end
                end
            end
            
        end
        
        function boolTarSelected = colorHover(obj,screenInfo,Eye,Key,color)
            boolTarSelected = obj.tarSelected(screenInfo,Eye,Key);
            if (boolTarSelected)
                I = obj.selTar;
                obj.targ(I).dat.setPars('color',color)
            end
        end
        
        function resetAllColors(obj,color)
            for i=1:obj.ntarg
                obj.targ(i).dat.setPars('color',color)
            end
        end
        
        
        function [boolTarSelected] = KeyChoice(obj,key)
            boolTarSelected = false;
            obj.selTar = [];
            for i=1:obj.ntarg
                if ismember(key,obj.keys{i})
                    obj.selTar = i;
                    boolTarSelected = true;
                end
                
            end
            
            
            
        end
        
    end
end