classdef ExtraDotClass < handle
    properties
        dotframeposit = []
        
        apXYD = [0 0 50];
        speed = [50];
        dotColor = [255 255 255]; % white dots default
        dotSize = 2;
        ap
        jump01
        
        framedot
        puntos
        
        dir
        
        frames 
        
        rseed
        rand_algorithm = 'mt19937ar'
        rstream
        
        method = ''
        probPerFrame = []
        
    end
    
    methods (Access = protected)
        function addDots(obj,frame_num,dir_sign,append)
            
            if nargin<4
                append=False;
            end
            
            jump = obj.jump01;
            N = length(frame_num);
            C = [0.5,0.5];
            
            %I avoid the borders so that the displacement gets seen
            R = 0.5 - jump; 
            dotsxy = create_dots(N,C,R,obj.rstream);
            
            ds = dir_sign;  
            jump_dir = jump * bsxfun(@times,repmat([cos(pi*obj.dir/180.0) -sin(pi*obj.dir/180.0)],N,1),ds);
            
            
            %save the dot position in scale 0...1 for the
            %frame and (frame+3)
            framedot = [frame_num(:),dotsxy];
            framedot = [framedot; frame_num(:)+3 ,dotsxy + jump_dir];
            
            if append
                obj.framedot = [obj.framedot; framedot];
            else
                obj.framedot = framedot;
            end
            
        end
    end
    
    methods
        function obj = ExtraDotClass(varargin)
            
            obj.setPars(varargin{:});
            
        end
        
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
            ForTrialData.dir        = obj.dir;
            ForTrialData.method     = obj.method;
            ForTrialData.probPerFrame = obj.probPerFrame;
        end
        
        function prepare_draw(obj,screenInfo)
            
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
            
            % create the square for the aperture
            %apRect = floor(createTRect(obj.apXYD, screenInfo));
            % USEFUL LOCAL VARS
            % variables that are sent to rex have been multiplied by a factor of 10 to
            % make sure they are integers. Now we have to convert them back so that
            % they are correct for plotting.
            %coh   	= obj.coh/1000;	%  % dotInfo.coh is specified on 0... (because
            
            % of rex needing integers), but we want 0..1
            apD = obj.apXYD(:,3); % diameter of aperture
            center = repmat(screenInfo.center,size(obj.apXYD(:,1)));
            
            % change the xy coordinates to pixels (y is inverted - pos on bottom, neg.
            % on top
            center = [center(:,1) + obj.apXYD(:,1)/10*screenInfo.ppd center(:,2) - ...
                obj.apXYD(:,2)/10*screenInfo.ppd]; % where you want the center of the aperture
            d_ppd 	= floor(apD/10 * screenInfo.ppd);	% size of aperture in pixels
            %dotSize = obj.dotSize; % probably better to leave this in pixels, but not sure
            
            %dotSize = screenInfo.ppd*dotInfo.dotSize/10;
            % ndots is the number of dots shown per video frame
            % we will place dots in a square the size of the aperture
            % - Size of aperture = Apd*Apd/100  sq deg
            % - Number of dots per video frame = 16.7 dots per sq.deg/sec,
            %        Round up, do not exceed the number of dots that can be
            %		 plotted in a video frame (dotInfo.maxDotsPerFrame)
            % maxDotsPerFrame was originally in setupScreen as a field in screenInfo,
            % but makes more sense in createDotInfo as a field in dotInfo
            
            
            % don't worry about pre-allocating, the number of dot fields should never
            % be large enough to cause memory problems
            
            % dxdy is an N x 2 matrix that gives jumpsize in units on 0..1
            %    	 deg/sec     * Ap-unit/deg  * sec/jump   =   unit/jump
            
            jump = (obj.speed/10) * (10/apD) * (3/screenInfo.monRefresh); %unit/jump. in units 0...1
            
            obj.ap.center = center;
            obj.ap.d_ppd  = d_ppd;
            obj.jump01   = jump;
            
            %to correct direction, multiply by: [cos(pi*obj.dir/180.0) -sin(pi*obj.dir/180.0)]
%             dxdy 	= repmat((obj.speed/10) * (10/apD) * (3/screenInfo.monRefresh) ...
%                 * [cos(pi*obj.dir/180.0) -sin(pi*obj.dir/180.0)], ndots,1);
            
%             
%             % ARRAYS, INDICES for loop
%             ss		= rand(rstream,ndots*3, 2); % array of dot positions raw [xposition yposition]
%             % divide dots into three sets...
%             Ls      = cumsum(ones(ndots,3))+repmat([0 ndots ndots*2], ndots, 1);
%             loopi   = 1; 	% loops through the three sets of dots
%             
%             
%             % THE MAIN LOOP
%             frames = 0;
%             priorityLevel = MaxPriority(curWindow,'KbCheck');
%             Priority(priorityLevel);
%             % index = 0;
            
            
            % how dots are presented: 1 group of dots are shown in the first frame, a
            % second group are shown in the second frame, a third group shown in the
            % third frame, then in the next frame, some percentage of the dots from the
            % first frame are replotted according to the speed/direction and coherence,
            % the next frame the same is done for the second group, etc.
            
            %GetSecs - test
            
            %variables persisent: Ls ss loopi coh coh_std ndots dxdy d_ppd frames
            
            
%             obj.frames = frames;
%             obj.vars_for_draw = struct('Ls',Ls,'ss',ss,'loopi',loopi,'coh',coh,'coh_std',coh_std,...
%                 'ndots',ndots,'dxdy',dxdy,'d_ppd',d_ppd,'apRect',apRect,...
%                 'dotSize',dotSize,'center',center,'rotationMat',rotationMat);
            obj.frames      = 0;
            obj.framedot    = [];
            obj.puntos      = [];
            
%             obj.cohframes = [];
%             obj.ncohdots  = [];
            
        end
        
        function add_balanced_dots_prob(obj,pBalanced,maxNumFrames)
            if nargin<3
                maxNumFrames = 400;
            end
            [frame,dirs] = calc_balanced_dots(pBalanced,maxNumFrames,obj.rstream);
            obj.addDots(frame,dirs,false);
            
            obj.method = 'prob_per_frame';
            obj.probPerFrame = pBalanced;
        end
            
        
        function draw(obj,screenInfo)
            curWindow = screenInfo.curWindow;
            d_ppd = obj.ap.d_ppd;
            center = obj.ap.center;
            
            obj.frames = obj.frames + 1;
            framedot = obj.framedot;
            inds_toshow = framedot(:,1)==obj.frames;
            
            
            %%    
            
            if sum(inds_toshow)>0
                
                dotsxy = framedot(inds_toshow,2:3);
                %convert to something that can be plotted
                dotsxy = floor(d_ppd * dotsxy); 
                dotsxy = [dotsxy - d_ppd/2]';

                Screen('DrawDots', curWindow, dotsxy, obj.dotSize, obj.dotColor, center);
                
                obj.puntos{obj.frames} = dotsxy;
            else
                obj.puntos{obj.frames} = [];
            end
            
        end
    end
end    
    
function dotsxy = create_dots(N,C,R,rstream)
% creates new dots uniformly on a circle.

    %N: number of dots
    %C: center
    %R: radius
    a = rand(rstream,N,1);
    b = rand(rstream,N,1);
    inds = b<a;
    atemp = a;
    a(inds) = b(inds);
    b(inds) = atemp(inds);
    dotsxy = [b.*R.*cos(2*pi*a./b)+C(1), b.*R.*sin(2*pi*a./b)+C(2)];
    
end
    
function [frame,dirs] = calc_balanced_dots(prob,maxNumFrames,rstream)
% calculates the input for the "addDots" method in ExtraDotClass

    if nargin<2
        maxNumFrames = 400;
    end

    add_dot = find(rand(rstream,maxNumFrames,1)<prob);

    frame = [add_dot,add_dot];%one positive, one negative
    dirs  = [ones(length(add_dot),1),-1*ones(length(add_dot),1)];
    
    
    frame = frame(:);
    dirs = dirs(:);
end
    