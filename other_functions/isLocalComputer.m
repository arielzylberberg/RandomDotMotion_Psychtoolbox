function [islocal,computer] = isLocalComputer()

[~, computer] = system('hostname');
computer = computer(1:end-1);

if isequal(computer,'Ariels-MacBook-Pro.local')
    islocal = 1;
else
    islocal = 0;
end