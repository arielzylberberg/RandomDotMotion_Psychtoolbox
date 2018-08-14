classdef trialOrgaClass < handle
    properties
        nTr
        cTr = 0;
        id_list = [];
    end
    
    methods
        function obj = trialOrgaClass(nTr)
            obj.nTr = nTr;
            obj.id_list = [1:nTr]';
        end
        
        function i = increse_trial_count(obj)
            obj.cTr = obj.cTr + 1;
            i = obj.cTr;
        end
        
        function tr_id = this_trial(obj)
            tr_id = obj.id_list(obj.cTr);
        end
        
        function append(obj,iTr)
            obj.id_list(end+1) = iTr; 
        end
        
        function islast = is_last_trial(obj)
            islast = obj.cTr==length(obj.id_list);
        end
        
        function [boolTrleft,numTrLeft] = trials_left(obj)
            boolTrleft = obj.cTr<length(obj.id_list);
            numTrLeft = length(obj.id_list) - obj.cTr;
        end
        
        
    end
end
  