function screenInfo = openExperiment(monWidth, viewDist, curScreen)
% screenInfo = openExperiment(monWidth, viewDist, curScreen
% Arguments:
%	monWidth ... viewing width of monitor (cm)
%	viewDist     ... distance from the center of the subject's eyes to
%	the monitor (cm)
%   curScreen         ... screen number for experiment
%                         default is 0.
% Sets the random number generator, opens the screen, gets the refresh
% rate, determines the center and ppd, and stops the update process 
% Used by both my dot code and my touch code.
% MKMK July 2006






mfilename
% % 1. SEED RANDOM NUMBER GENERATOR
% screenInfo.rseed = [];
% rseed = sum(100*clock);
% rand('state',rseed);
% %screenInfo.rseed = sum(100*clock);
% %rand('state',screenInfo.rseed);

% computer name
[~, computer] = system('hostname');
screenInfo.computer = computer(1:end-1);




if isequal(screenInfo.computer,'boulardii.local')
    % small MBBI
    room = 1;
elseif contains(screenInfo.computer,'dyn.columbia.edu')
    % large MBBI
    room = 2;
else
    room = 0;
end


if nargin==0
    if room==1
        monWidth = 37;
        viewDist = 68;
    elseif room==2
        monWidth = 35.5;
        viewDist = 71;
    else
        monWidth = 37;
        viewDist = 68;
    end
end
    

if isLocalComputer
    Screen('Preference', 'SkipSyncTests', 1);
end

% ---------------
% open the screen
% ---------------

% make sure we are using openGL
AssertOpenGL;

if nargin < 3
%     curScreen = 0;
    curScreen=max(Screen('Screens'));
end
screenInfo.curScreen = curScreen;

%small psychophysics room
if room==1
    oldRes = SetResolution(curScreen,1280,960,75);
elseif room==2
    oldRes = SetResolution(curScreen,1280,960,75);
else
    disp('unspecified monitor')
end


% added to make stuff behave itself in os x with multiple monitors
Screen('Preference', 'VisualDebugLevel',2);
%%%%

% Set the background to the background value.
screenInfo.bckgnd = 0;
% if isequal(screenInfo.computer,'Ariels-MacBook-Pro.local')
if isLocalComputer
    rect = [0,0,800,600];
    [screenInfo.curWindow, screenInfo.screenRect] = Screen('OpenWindow', curScreen, screenInfo.bckgnd,rect,32, 2);
    % [screenInfo.curWindow, screenInfo.screenRect] = Screen('OpenWindow', curScreen, screenInfo.bckgnd,rect,32, 2,[],1);
    
    
%     Screen('BlendFunction', screenInfo.curWindow, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);%??
else
    [screenInfo.curWindow, screenInfo.screenRect] = Screen('OpenWindow', curScreen, screenInfo.bckgnd,[],32, 2);
end

%small psychophysics room
if room==1 % small psych room, mbbi
    % gamma table
    % tabla = load('./gamma_tables/gammaTable_SmallPsychRoom_20171004.mat');
    tabla = load('./gamma_tables/gammaTableSmallPsychRoom_08-Jun-2018.mat');
    Screen('LoadNormalizedGammaTable',screenInfo.curScreen,tabla.gammaTable1*[1,1,1]);
    
elseif room==2 % large psych room, mbbi
    
    tabla = load('./gamma_tables/gammaTableLargePsychRoom_26-Feb-2019.mat');
    Screen('LoadNormalizedGammaTable',screenInfo.curScreen,tabla.gammaTable1*[1,1,1]);
    
% else
%     tabla = [0:255]'/255; %identidad
%     Screen('LoadNormalizedGammaTable',screenInfo.curScreen,tabla*[1,1,1]);
end

% [screenInfo.curWindow, screenInfo.screenRect] = Screen('OpenWindow', curScreen, screenInfo.bckgnd,[0 0 800 600],32, 2);
% [screenInfo.curWindow, screenInfo.screenRect] = Screen('OpenWindow', curScreen, screenInfo.bckgnd,[0 0 1280 960],32, 2);
screenInfo.dontclear = 0; % 1 gives incremental drawing (does not clear buffer after flip)

%get the refresh rate of the screen
% need to change this if using crt, would be nice to have an if
% statement...
%screenInfo.monRefresh = Screen(curWindow,'FrameRate');
spf = Screen('GetFlipInterval', screenInfo.curWindow);      % seconds per frame
screenInfo.monRefresh = 1/spf;    % frames per second
screenInfo.frameDur = 1000/screenInfo.monRefresh;

screenInfo.center = [screenInfo.screenRect(3) screenInfo.screenRect(4)]/2;   	% coordinates of screen center (pixels)

% determine pixels per degree
% (pix/screen) * ... (screen/rad) * ... rad/deg
screenInfo.ppd = pi * screenInfo.screenRect(3) / atan(monWidth/viewDist/2) / 360;    % pixels per degree

screenInfo.monWidth = monWidth;
screenInfo.viewDist = viewDist;

HideCursor

% if reward system is hooked up, rewardOn = 1, otherwise rewardOn = 0;
screenInfo.rewardOn = 0;
%screenInfo.rewardOn = 1;

% get reward system ready
% screenInfo.daq=DaqDeviceIndex;

Screen('TextFont',screenInfo.curWindow,'Arial')

Screen('TextSize',screenInfo.curWindow,20)
