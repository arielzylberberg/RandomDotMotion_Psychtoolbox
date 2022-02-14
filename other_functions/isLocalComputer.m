function [islocal,computer] = isLocalComputer()

[~, computer] = system('hostname');
computer = computer(1:end-1);
computer = lower(computer); 

if contains(computer,'jians') || contains(computer,'ariels') || ...
        contains(computer,'zylberberg')
    islocal = 1;
else
    islocal = 0;
end