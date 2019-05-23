function [y,uni_x] = Rtable(x)
% y = function Rtable(x)
% funcion parecida al "table" de R. Dado x, hace un unique y calcula
% cuantas ocurrencias de cada valor hay en el vector x

uni_x = unique(x);
y = nan(size(uni_x));
if isnumeric(uni_x)
    for i=1:length(uni_x)
        y(i) = sum(x==uni_x(i));
    end
else
    for i=1:length(uni_x)
        y(i) = sum(ismember(x,uni_x(i)));
    end
end