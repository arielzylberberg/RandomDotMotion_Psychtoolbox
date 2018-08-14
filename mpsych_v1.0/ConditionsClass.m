classdef ConditionsClass < handle
    properties
        conditions
        nTr
        idx_conditions
        rep_id
        seeds
    end
    
    methods
        function obj = ConditionsClass()
        end
        
        function createFactorialTrialList(obj,uniValsCell,nTrialsPerCondition)
            uniValsStruct = cell2struct(uniValsCell(2:2:end),uniValsCell(1:2:end),2);
            
            c = struct2cell(uniValsStruct);
            str = 'c{1}';
            for i=2:length(c)
                str = [str,',c{',num2str(i),'}'];
            end
            
            uni_conditions  = eval(['combvec(',str,')']);
            n = size(uni_conditions,1);
            idx_conditions  = [1:n]';
            idx_conditions = repmat(idx_conditions,nTrialsPerCondition,1);
            nrep = bsxfun(@times,ones(n,1),[1:nTrialsPerCondition]);
            nrep = nrep(:);
            
            ind_shuffle = randperm(length(idx_conditions));
            idx_conditions = idx_conditions(ind_shuffle);
            nrep = nrep(ind_shuffle);
            
            conditionMatrix = uni_conditions(idx_conditions,:);
            
            fields = fieldnames(uniValsStruct);
            for i=1:length(fields)
                conditions.(fields{i}) = conditionMatrix(:,i);
            end
            
            nTr = length(conditions.(fields{1}));
            
            obj.nTr = nTr;
            obj.conditions = conditions;
            obj.idx_conditions = idx_conditions;
            obj.rep_id = nrep;
            
        end
        
        function makeSeeds(obj,type,Nreps)
            if nargin<3
                Nreps = 1;
            end
            obj.seeds = makeSeeds(obj.idx_conditions,type,Nreps);
        end
        
        function duplicateSeedsThatDifferOn(obj,field)
            %index of the field over which to duplicate seeds
            ind = ismember(fields(obj.conditions),field);
            if sum(ind)==0
                error('unknown field')
            end
            
            %make matrix from conditions, igonring "field"
            a = struct2array(obj.conditions);
            c = [a(:,~ind), obj.rep_id];
            
            %use the seeds from the condition with lower
            %value for the "field" column
            idx = find(a(:,ind) == min(a(:,ind)));
            uni_seeds =obj.seeds(idx);
            for i=1:length(idx)
                inds = find_rows(c(idx(i),:),c);
                obj.seeds(inds) = uni_seeds(i);
            end
            
            
        end
        
        
        
    end
    
end


