classdef DotsClass < handle
    properties
        df
        ndf
    end
    methods 
        function obj = DotsClass(NumberOfRDMs)
            obj.ndf = NumberOfRDMs;
            for i=1:obj.ndf
                obj.df{i} = DotInfoClass();
            end
        end
        
        function setPars(obj,id,varargin)
            obj.df{id}.setPars(varargin{:});
        end
        
        function par = getPar(obj,id,parname)
            par = obj.df{id}.(parname);
        end
        
        function ForSessionData = sessionInfo(obj)
            for i=1:obj.ndf
                ForSessionData{i} = obj.df{i}.sessionInfo();
            end
        end
        
        function prepare_draw(obj,screenInfo)
            for i=1:obj.ndf
                obj.df{i}.prepare_draw(screenInfo);
            end
        end
%         function sampleDuration(obj)
%             for i=1:obj.ndf
%                 obj.df{i}.sampleDuration();
%             end
%         end
    end
end