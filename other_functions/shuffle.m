function [y,inds] = shuffle(x)
%function y = shuffle(x)
%shufflea el vector 1-d
inds = randperm(length(x));
y = x(inds);
