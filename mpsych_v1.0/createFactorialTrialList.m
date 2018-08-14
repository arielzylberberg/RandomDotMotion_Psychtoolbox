function [conditions,nTr,idx_conditions] = createFactorialTrialList(uniValsCell,nTrialsPerCondition)
%example:
%[conditions] = createFactorialTrialList(struct('a',[1 2],'b',[3 4]),4)

uniValsStruct = cell2struct(uniValsCell(2:2:end),uniValsCell(1:2:end),2);

c = struct2cell(uniValsStruct);
str = 'c{1}';
for i=2:length(c)
    str = [str,',c{',num2str(i),'}'];
end

uni_conditions  = eval(['combvec(',str,')']);
idx_conditions  = [1:size(uni_conditions,1)]';
idx_conditions = repmat(idx_conditions,nTrialsPerCondition,1);

idx_conditions = shuffle(idx_conditions);
%conditionMatrix = repmat(uni_conditions,nTrialsPerCondition,1);
conditionMatrix = uni_conditions(idx_conditions,:);


% ntr         = size(conditionMatrix,1);
% inds        = shuffle(1:ntr);
% conditionMatrix  = conditionMatrix(inds,:);

fields = fieldnames(uniValsStruct);
for i=1:length(fields)
    conditions.(fields{i}) = conditionMatrix(:,i);
end

nTr = length(conditions.(fields{1}));


    