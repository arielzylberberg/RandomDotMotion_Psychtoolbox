classdef TimeClass < handle
    properties
        dat
        
    end
    
    methods
        function obj = TimeClass(varargin)
            for i=1:length(varargin)
                obj.dat.(varargin{i}) = [];
            end
        end
        
        function setPars(obj,f,val)
            fields = fieldnames(obj.dat);
            if ~ismember(f,fields)
                error('unrecognized field');
            else
                obj.dat.(f) = val;
            end
            
        end
        
        function sample(obj,varargin)
            
            f = varargin{1};
            d = varargin{2};
            
            fields = fieldnames(obj.dat);
            if ~ismember(f,fields)
                error('unrecognized field');
            end
            
            dt = cell2struct(d(2:2:end),d(1:2:end),2);
            if dt.type == 0 %constant
                obj.dat.(f) = makeInterval(dt.type,dt.min,[],[]);
            elseif dt.type == 1 % uniform
                obj.dat.(f) = makeInterval(dt.type,dt.min,dt.max,[]);
            elseif dt.type == 2 % exponential
                obj.dat.(f) = makeInterval(dt.type,dt.min,dt.max,dt.mean);
            end
            
        end
        
        function ForTrialData = trialInfo(obj)
            ForTrialData = obj.dat;
        end
    end
end