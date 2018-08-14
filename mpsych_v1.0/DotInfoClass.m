classdef DotInfoClass < handle
    properties
        %         numDotField = 1;
        apXYD = [0 0 50];
        speed = [50];
        maxDotTime = [3];
        dotColor = [255 255 255]; % white dots default
        % dot size in pixels
        dotSize = 2;
        
        % fixation x,y coordinates
        % dotInfo.fixXY = [0 -20];
        
%         fixXY = [0 0];
%         fixDiam = 3;
%         fixColor = [0 255 255];
        
        dotDensity = 16.7 %dots per sq.deg/sec
        maxDotsPerFrame = 150
        
        %set of possible values
        % creo que es mejor sacar esto de aca
        cohSet = [0, 3.2, 6.4, 12.8, 25.6, 51.2]/100 * 1000
%         cohSet = [51.2]/100 * 1000
        dirSet = [0,180] %anticlockwise ??
        cohStdSet
        
        doMirror = false
        
        monRefresh
        frames
        vars_for_draw
        puntos
        cohframes
        ncohdots
        rseed
        rand_algorithm = 'mt19937ar'
        rstream
        
        % include response modality in class??
        %enforceFix
        %allowResp?
%         typeInt = 2;
%         % typeInt = 0 fixed delay, minNum is actual delay time (need minNum)
%         % typeInt = 1 uniform distribution (need minNum and maxNum)
%         % typeInt = 2 exponential distribution (need all three)
%         minInt = 0.3;
%         maxInt  = 1;
%         meanInt = .5;


        %specific to the trial;with some defaults:
        coh
        dir
%         stimdur
        coh_std = 0
%         stimlife
        
        

    end
    methods
        function obj = DotInfoClass(varargin)
            %instantiates object with default values
            if ~isempty(varargin)
                obj.setPars(varargin{:})
            end
            obj.sampleRandomCoh();
            obj.sampleRandomDir();
%             obj.sampleDuration();
            
        end
        function sampleRandomDir(obj)
            ind = ceil(rand*length(obj.dirSet));
            obj.dir = obj.dirSet(ind);
        end
        
        function sampleRandomCoh(obj)
            ind = ceil(rand*length(obj.cohSet));
            obj.coh = obj.cohSet(ind);
        end
        
%         function sampleDuration(obj)
%             %one problem now is that the duration is independent of the 
%             %seed, and thus dots may be identical but shown for different 
%             %durations
%             obj.stimdur = makeInterval(obj.typeInt,obj.minInt,obj.maxInt,obj.meanInt);
%             
%         end
        
        function setPars(obj,varargin) %overwrite defaults
            for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
        end
        
        function ForTrialData = trialInfo(obj)
            ForTrialData.puntos     = obj.puntos;
            ForTrialData.rseed      = obj.rseed;
            ForTrialData.coh        = obj.coh;
            ForTrialData.coh_std    = obj.coh_std;
            ForTrialData.dir        = obj.dir;
            ForTrialData.cohframes  = obj.cohframes;
            ForTrialData.ncohdots   = obj.ncohdots;
            
%             ForTrialData.stimdur =  obj.stimdur;
        end

        function prepare_draw(obj,screenInfo,run_dummy)
            
            if nargin<3
                run_dummy = false;
            end
%             obj.stimlife = sec2frames(obj.stimdur);
            
            %maybe define
            if ~run_dummy
                curWindow = screenInfo.curWindow;
                dontclear = screenInfo.dontclear;
            end
            
            rseed = obj.rseed;
            
            % SEED THE RANDOM NUMBER GENERATOR ... if "[]" is given, reset
            % the seed "randomly"... this is for VAR/NOVAR conditions
            % CHANGE THIS TO PERSISTENT SEED !!!!!!
            if ~isempty(rseed) && length(rseed) == 1
                rstream = RandStream(obj.rand_algorithm,'Seed',rseed);
            else
                rseed = sum(100*clock);
                rstream = RandStream(obj.rand_algorithm,'Seed',rseed);
            end
            obj.rstream = rstream;
            obj.rseed = rseed;
            
            
%             if ~isempty(rseed) && length(rseed) == 1
%                 rand('state', rseed);
%             elseif ~isempty(rseed) && length(rseed) == 2
%                 rand('state', rseed(1)*rseed(2));
%             else
%                 rseed = sum(100*clock);
%                 rand('state', rseed);
%             end
            
            % create the square for the aperture
            apRect = floor(createTRect(obj.apXYD, screenInfo));
            % USEFUL LOCAL VARS
            % variables that are sent to rex have been multiplied by a factor of 10 to
            % make sure they are integers. Now we have to convert them back so that
            % they are correct for plotting.
            coh   	= obj.coh/1000;	%  % dotInfo.coh is specified on 0... (because
            coh_std = obj.coh_std/1000;
            %esto no funciona en matlab viejo !!
%             if isprop(obj,'coh_std')
%                 coh_std = obj.coh_std/1000;
%             else
%                 coh_std = 0;
%             end
            
            % of rex needing integers), but we want 0..1
            apD = obj.apXYD(:,3); % diameter of aperture
            % dotInfo.apXYD(:,1:2)
            % screenInfo.center;
            % disp('dotInfo.apXYD')
            % dotInfo.apXYD(:,1:2)/10*screenInfo.ppd
            center = repmat(screenInfo.center,size(obj.apXYD(:,1)));
            
            % change the xy coordinates to pixels (y is inverted - pos on bottom, neg.
            % on top
            center = [center(:,1) + obj.apXYD(:,1)/10*screenInfo.ppd center(:,2) - ...
                obj.apXYD(:,2)/10*screenInfo.ppd]; % where you want the center of the aperture
            d_ppd 	= floor(apD/10 * screenInfo.ppd);	% size of aperture in pixels
            dotSize = obj.dotSize; % probably better to leave this in pixels, but not sure
            %dotSize = screenInfo.ppd*dotInfo.dotSize/10;
            % ndots is the number of dots shown per video frame
            % we will place dots in a square the size of the aperture
            % - Size of aperture = Apd*Apd/100  sq deg
            % - Number of dots per video frame = 16.7 dots per sq.deg/sec,
            %        Round up, do not exceed the number of dots that can be
            %		 plotted in a video frame (dotInfo.maxDotsPerFrame)
            % maxDotsPerFrame was originally in setupScreen as a field in screenInfo,
            % but makes more sense in createDotInfo as a field in dotInfo
            ndots 	= min(obj.maxDotsPerFrame, ceil(obj.dotDensity * apD .* apD * 0.01 / screenInfo.monRefresh));
            
            % don't worry about pre-allocating, the number of dot fields should never
            % be large enough to cause memory problems
            
            % dxdy is an N x 2 matrix that gives jumpsize in units on 0..1
            %    	 deg/sec     * Ap-unit/deg  * sec/jump   =   unit/jump
            
            dxdy 	= repmat((obj.speed/10) * (10/apD) * (3/screenInfo.monRefresh) ...
                * [cos(pi*obj.dir/180.0) -sin(pi*obj.dir/180.0)], ndots,1);
            % ARRAYS, INDICES for loop
            ss		= rand(rstream,ndots*3, 2); % array of dot positions raw [xposition yposition]
            % divide dots into three sets...
            Ls      = cumsum(ones(ndots,3))+repmat([0 ndots ndots*2], ndots, 1);
            loopi   = 1; 	% loops through the three sets of dots
            
            
            %disp('after one loop')
            % loop length is determined by the field "dotInfo.maxDotTime"
            % if none given, loop until "continue_show=0" is set by other means (eg
            % user response), otherwise loop until dotInfo.maxDotTime
            % always one video frame per loop
            
            %     if ~isfield(dotInfo,'maxDotTime') || (isempty(dotInfo.maxDotTime) && ndots>0)
            %         continue_show = -1;
            %     elseif ndots > 0,
            %         continue_show = round(dotInfo.maxDotTime*screenInfo.monRefresh);
            %     else
            %         continue_show = 0;
            %     end;
            
            
            
            % THE MAIN LOOP
            frames = 0;
            
            if ~run_dummy % to run as dummy
                priorityLevel = MaxPriority(curWindow,'KbCheck');
                Priority(priorityLevel);
            end
            %             index = 0;
            
            % make sure the fixation still on
            % for i = showtar
            %     Screen('FillOval', screenInfo.curWindow, targets.colors(i,:), targets.rects(i,:));
            % end
%             Screen('DrawingFinished',curWindow,dontclear);
            
            if obj.doMirror
                rotationAxis = [sin(pi*obj.dir/180.0) cos(pi*obj.dir/180.0) 0];
                rotationMat  = rotationmat3D(pi,rotationAxis);
            else
                rotationMat = [];
            end


            % how dots are presented: 1 group of dots are shown in the first frame, a
            % second group are shown in the second frame, a third group shown in the
            % third frame, then in the next frame, some percentage of the dots from the
            % first frame are replotted according to the speed/direction and coherence,
            % the next frame the same is done for the second group, etc.
            
            %GetSecs - test
            
            
            %variables persisent: Ls ss loopi coh coh_std ndots dxdy d_ppd frames
            
            
            obj.frames = frames;
            obj.vars_for_draw = struct('Ls',Ls,'ss',ss,'loopi',loopi,'coh',coh,'coh_std',coh_std,...
                'ndots',ndots,'dxdy',dxdy,'d_ppd',d_ppd,'apRect',apRect,...
                'dotSize',dotSize,'center',center,'rotationMat',rotationMat);
            obj.puntos    = [];
            obj.cohframes = [];
            obj.ncohdots  = [];
            
        end
        
        function draw(obj,screenInfo,run_dummy) %what to do on every call
            
            if nargin<3
                run_dummy = false;
            end
            
            %maybe define
            struct2vars(obj.vars_for_draw);
            rstream = obj.rstream;
            
            curWindow = screenInfo.curWindow;
            dotColor  = obj.dotColor;
            
            dontclear = screenInfo.dontclear;
            
            
            % ss is the matrix with the 3 sets of dot positions, dots from the last 2 positions + current
            % Ls picks out the set (for ex., with 5 dots on the screen at a time, 1:5, 6:10, or 11:15)
            Lthis  = Ls(:,loopi);  % Lthis now has the dot positions from 3 frames ago, which is what is then
            % moved in the current loop
            this_s = ss(Lthis,:); % this is a matrix of random #s - starting positions for dots not moving coherently
            % update the loop pointer
            loopi = loopi+1;
            if loopi == 4,
                loopi = 1;
            end
            % compute new locations, how many dots move coherently
            cohframe = coh + randn(rstream)*coh_std;
            
            L = rand(rstream,ndots,1) < abs(cohframe);
            nCohDotsAux = sum(L) * sign(cohframe);
            if cohframe >= 0
                this_s(L,:) = this_s(L,:) + dxdy(L,:);	% offset the selected dots
            else %make motion in opposite direction
                this_s(L,:) = this_s(L,:) - dxdy(L,:);	% offset the selected dots - opposite
            end
            
%             if sign(cohframe)==sign(coh) || (coh==0 && sign(cohframe)>0)
%                 this_s(L,:) = this_s(L,:) + dxdy(L,:);	% offset the selected dots
%             else %make motion in opposite direction
%                 this_s(L,:) = this_s(L,:) - dxdy(L,:);	% offset the selected dots - opposite
%             end
            
            if sum(~L) > 0
                this_s(~L,:) = rand(rstream,sum(~L),2);	    % get new random locations for the rest
            end
            % wrap around - check to see if any positions are greater than one or less than zero
            % which is out of the square aperture, and then replace with a dot along one
            % of the edges opposite from direction of motion.
            N = sum((this_s > 1 | this_s < 0)')' ~= 0;
            if sum(N) > 0
                xdir = sin(pi*obj.dir/180.0);
                ydir = cos(pi*obj.dir/180.0);
                
                % flip a weighted coin to see which edge to put the replaced
                % dots
                if rand(rstream) < abs(xdir)/(abs(xdir) + abs(ydir))
                    this_s(find(N==1),:) = [rand(rstream,sum(N),1) (xdir > 0)*ones(sum(N),1)];
                else
                    this_s(find(N==1),:) = [(ydir < 0)*ones(sum(N),1) rand(rstream,sum(N),1)];
                end
            end
            % convert to stuff we can actually plot
            this_x = floor(d_ppd * this_s);	% pix/ApUnit
            
            % this assumes that zero is at the top left, but we want it to be
            % in the center, so shift the dots up and left, which just means
            % adding half of the aperture size to both the x and y direction.
            dot_show = (this_x - d_ppd/2)';
            
            inds = (dot_show(1,:).^2+dot_show(2,:).^2)>(d_ppd/2)^2; % para que quede circular
            dot_show(:,inds) = [];
            
            
            if obj.doMirror && ~isempty(dot_show)
                dot_show_aux = cat(1,dot_show,zeros(1,size(dot_show,2)));
                dot_show3d = round(rotationMat * dot_show_aux);
                dot_show = dot_show3d(1:2,:);
            end
            
            
            % after all computations, flip, this draws dots from previous loop,
            % first time through doesn't do anything
            %     Screen('Flip', curWindow,0,dontclear);
            
            % setup the mask - we will only be able to see a circular aperture,
            % although dots moving in a square aperture. Minimizes the edge
            % effects.
            
            
%             Screen('BlendFunction', curWindow, GL_ONE, GL_ZERO);
%             
%             % want targets to still show up
% %             Screen('FillRect', curWindow, [0 0 0 255]);
%             
%             
%             % square that dots do not show up in
%             Screen('FillRect', curWindow, [0 0 0 0], apRect);
%             % circle that dots do show up in
%             Screen('FillOval', curWindow, [0 0 0 255], apRect);
%             
%             Screen('BlendFunction', curWindow, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
            
            
            % now do actual drawing commands, although nothing drawn until next
            % loop
            % dots
            if ~isempty(dot_show) && ~run_dummy
                Screen('DrawDots', curWindow, dot_show, dotSize, dotColor, center);
            end
            
            %     % targets
            %     for i = showtar
            %         Screen('FillOval', screenInfo.curWindow, targets.colors(i,:), targets.rects(i,:));
            %     end
            
            % tell ptb to get ready while doing computations for next dots
            % presentation
            
%             Screen('DrawingFinished',curWindow,dontclear);
%             Screen('BlendFunction', curWindow, GL_ONE, GL_ZERO);
            obj.frames = obj.frames + 1;
            
            %save the dots
            
%             dot_show_aux = dot_show;
%             inds = sqrt(dot_show_aux(1,:).^2+dot_show_aux(2,:).^2)>d_ppd/2; % para que quede circular
%             dot_show_aux(:,inds) = [];
%             obj.puntos{obj.frames} = dot_show_aux;
            obj.puntos{obj.frames} = dot_show;
            
            %end save the dots
            
            %save the time-varying coherence
            obj.cohframes(obj.frames,:) = cohframe(:);
            obj.ncohdots(obj.frames,:) = nCohDotsAux(:);
            
%             if obj.frames == 1
%                 start_time = GetSecs;
%             end
            
            % update the dot position array for the next loop
            ss(Lthis, :) = this_s;
            
            
            obj.vars_for_draw = struct('Ls',Ls,'ss',ss,'loopi',loopi,'coh',coh,'coh_std',coh_std,...
                'ndots',ndots,'dxdy',dxdy,'d_ppd',d_ppd,'apRect',apRect,...
                'dotSize',dotSize,'center',center,'rotationMat',rotationMat);
            
            % check for end of loop
            %     continue_show = continue_show - 1;
            
            %user may terminate the dots by pressing certain keyboard keys defined
            %by "keys"
            
            %     % this is changed so now pressing the space bar will cause a signal to
            %     % be sent so that the experiment will end after this trial
            %     if ~isempty(keys)
            %         [keyIsDown,secs,keyCode] = KbCheck(-1);
            %         if keyIsDown
            %             % send abort signal
            %             if keyCode(abort)
            % %                 response{1} = find(keyCode(abort));
            %                 response{1} = 1;
            %                 continue_show = 0;
            %             end
            %             % end trial, have response
            %             if any(keyCode(keys))
            %                 response{3} = find(keyCode(keys));
            %                 continue_show = 0;
            %                 response_time = secs;
            %             end
            %         end
            %     end
            %
            %     if ~isempty(mouse)
            %         [x,y,buttons] = GetMouse(curWindow);
            %         % check = 0 means exit dots, check = 1 means continue showing dots
            %         check = 0;
            %         if buttons
            %             % mouse was pressed, if hold is on, and we know fixation
            %             % position, make sure holding correct place
            %             if waitpress == 0
            %                 if isfield(targets,'select')
            %                     check = checkPosition(x,y,h(1),k(1),r(1));
            %                 end
            %             else
            %                 % if hold is not on, and this is fixed duration, we don't
            %                 % care if the subject touches the screen - if reaction
            %                 % time, then touching means exit dots
            %                 if dotInfo.trialtype(1) == 1
            %                     check = 1;
            %                 end
            %             end
            %         else
            %             % mouse was not pressed.
            %             % if waiting for a mouse press, continue paradigm
            %             if waitpress == 1
            %                 check = 1;
            %             end
            %         end
            %         if ~check
            %             % for fixed duration, exiting early is always an error.
            %             if dotInfo.trialtype(1) == 1
            %                 response{2} = 0;
            %             else
            %                 % buttons is zero if we are doing reaction time where the
            %                 % subject has to hold during fixation, and releasing the
            %                 % mouse signifies end of the dots, otherwise should tell
            %                 % you the xy position. Eventually, I guess we should make
            %                 % it so we can use two mouse buttons as the answer...
            %                 if buttons
            %                     response{2} = [x y];
            %                     %response{2} = find(buttons(mouse));
            %                 else
            %                     response{2} = 0;
            %                 end
            %             end
            %             response_time = GetSecs;
            %             continue_show = 0;
            %         end
            %     end
        end
    end
end



%
%
%
%
%
% % targets
% % target default xy, this is what will be used if setting target positions
% % manually, if setting automatically, will use same distance as this from
% % either the fixation or the aperture center [x1 y1; x2 y2]
% % dotInfo.tarXY = [50 50; -50 -50];
% % dotInfo.tarXY       = [70 70; -70 70;-70 -70;70 -70];
% %
% % if inputtype == 1
% %     dotInfo.keys     = [KbName('i') KbName('e') KbName('c') KbName('m')];
% %
% % end
% % % dotInfo.tarPatch    = [1 1 1 1]; % to which patch each target is associated with; relative to dotInfo.apXYD
% % % dotInfo.tarDir      = [1 nan 2 nan]; % relative to dotInfo.dirSet
% %
% %
% % % target diameters
% % % dotInfo.tarDiam = [20 20];
% % dotInfo.tarDiam = [15 6 15 6]; %mantener que el 1ro y 3ro sean targets, y los otros cues
%
% % to make the touch area different from the target - this is the new radius
% % that the monkey has to touch, must be same length as
% % [dotInfo.fixDiam dotInfo.tarDiam]
% dotInfo.touchbig = [];
% % dotInfo.touchbig = [30 30 30];
%
% % target color - default color of targets, must be a single rgb set, if you
% % want the incorrect target(s) a different color, use dotInfo.wrongColor
%
% dotInfo.tarColor = [255 0 0; 255 0 0];
%
%
%
% % incorrect target color - if different from rest of targets
% dotInfo.wrongColor = [];
% % dotInfo.wrongColor = [0 150 150];
%
% % trialInfo.auto
% % column 1: how to determine position of dots (relative to what): 1 to set
% % manually, 2 to use fixation as center point, 3 to use aperture as center
% % column 2: 1 to set coherence manually (just use one coherence repeatedly
% % or set somewhere else), 2 random
% % column 3: 1 to set direction manually (just use one direction repeatedly
% % or set somewhere else), 2 random, 3 correction mode
% % dotInfo.auto = [3 2 2];
% dotInfo.auto = [1 2 2];
%
% % array for timimg
% % CURRENTLY THERE IS AN ALMOST ONE SECOND DELAY FROM THE TIME DOTSX IS
% % CALLED UNTIL THE DOTS START ON THE SCREEN! THIS IS BECAUSE OF PRIORITY.
% % NEED TO EVALUATE WHETHER PRIORITY IS REALLY NECESSARY.
% %
% % FOR KEYPRESS ROUTINES
% % for reaction time task
% % 1. fixation on until targets on - if this is zero, than targets come on
% %       with fixation, if don't want to show targets, make length 2
% % 2. fixation on until dots on
% % 3. max duration dots on
% %
% %
% % for fixed duration task
% % 1. fixation on until targets on - if this is zero, than targets come on
% %       with fixation, if it is greater then time to dots on, comes on
% %       after dots off. if greater than fix off, will come on at same time
% %       as fix off.
% % 2. fixation on until dots on
% % 3. duration dots on
% % 4. dots off until fixation off
% % 5. time limit for keypress after fixation off
% %
% % FOR TOUCHSCREEN (USING MOUSE) ROUTINES
% % for reaction time task
% % 1. time limit to fixate
% % 2. fixation on until targets on - if this is zero, than targets come on
% %       with fixation
% % 3. fixation acquired until dots on
% % 4. max duration dots on
% % 5  time limit to touch after removing finger
% %
% % for fixed duration task
% % 1. time limit to fixate
% % 2. fixation acquired until targets on - if this is zero, than targets come on
% %       with fixation, if it is greater than time to dots on, comes on
% %       after dots off. if greater than fix off, will come on at same time
% %       as fix off.
% % 3. fixation acquired until dots on
% % 4. duration dots on
% % 5. dots off until fixation off
% % 6. time limit to touch after removing finger
% %
% % (this will be fed into MakeInterval - to use a random distribution see
% % help MakeInterval and set interval parameters in touchdottask)
%
%
% if inputtype == 1
%     if dotInfo.trialtype(1) == 1
%         dotInfo.durTime = [1 2 1 1 3];
%     else
%         dotInfo.durTime = [1 1.3 10];
%     end
% else
%     if dotInfo.trialtype(1) == 1
%         dotInfo.durTime = [4 2 1 1 0 3];
%     else
%         dotInfo.durTime = [4 0 1 3 3];
%     end
% end
%
% % variables for making delay periods
% % itype = 0 fixed delay, minNum is actual delay time (need minNum)
% % itype = 1 uniform distribution (need minNum and maxNum)
% % itype = 2 exponential distribution (need all three)
% dotInfo.itype = 0;
% % min - get directly from trialInfo
% dotInfo.imax = [];
% dotInfo.imean = [];
%
% dotInfo.itype = [0 2 0];
% dotInfo.imax  = [nan  2 nan];
% dotInfo.imean = [nan .4 nan];
%
%
% %%%%%%% BELOW HERE IS STUFF THAT SHOULD GENERALLY NOT BE CHANGED!
%
% % make time distributions - only has affect if variable distribution
% dotInfo.minTime = makeInterval2(dotInfo.itype,dotInfo.durTime,dotInfo.imax,dotInfo.imean);
%
%
% %
% % dotInfo.maxDotsPerFrame = 150;   % by trial and error.  Depends on graphics card
% % % Use test_dots7_noRex to find out when we miss frames.
% % % The dots routine tries to maintain a constant dot density, regardless of
% % % aperture size.  However, it respects MaxDotsPerFrame as an upper bound.
% % % The value of 53 was established for a 7100 with native graphics card.
% %
% % % possible keys active during trial
% % dotInfo.keyEscape   = KbName('escape');
% % dotInfo.keySpace    = KbName('space');
% % dotInfo.keyReturn   = KbName('return');
% %
% % if inputtype == 1
% %     %      dotInfo.keyLeft     = KbName('leftarrow');
% %     %      dotInfo.keyRight    = KbName('rightarrow');
% % else
% %     mouse_left      = 1;
% %     mouse_right     = 2;
% %     dotInfo.mouse   = [mouse_left, mouse_right];
% % end
% %
% % if nargout < 1
% %     if inputtype == 1
% %         save keyDotInfoMatrix dotInfo
% %     else
% %         save dotInfoMatrix dotInfo
% %     end
% % end
