function struct2vars(struc,varargin)
% function struct2vars(struc,varargin)
if nargin>1
    names = varargin;
else
    names = fields(struc);
end
for i = 1:length(names)
%     assignin('base',names{i},struc.(names{i}));
    assignin('caller',names{i},struc.(names{i}));
end
        