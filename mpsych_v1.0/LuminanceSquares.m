classdef LuminanceSquares < handle
    properties
        
        pars
        vars_for_draw
        dir
        
        stimuli
        
        ncols = 4
        nrows = 1
        square_height_deg = 0.56
        square_width_deg = 0.14
        
        mean_lum %?? decide on units
        std_lum = 0.1
        
        % center of rect in deg relative to center of screen
        cx = 0
        cy = 0
        
%         uni_signal = [0:3]*pi/240;
%         uni_dir    = [-1, 1];
%         uni_stdev  = [pi/32, pi/24, pi/16];
        
        inter_frames_interval = 5
        frames
        rseed
        rand_algorithm = 'mt19937ar'
        rstream
        
    end
    
    
    methods
        
        % defined here
        function obj = LuminanceSquares(varargin)
            %instantiates object with default values
            if ~isempty(varargin)
                obj.setPars(varargin{:})
            end
        end
        
        function setPars(obj,varargin)
            for i=1:2:length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
        end
        
        function ForTrialData = trialInfo(obj)
            % save
            ForTrialData.mean_lum = obj.mean_lum;
            ForTrialData.std_lum = obj.std_lum;
            ForTrialData.cx = obj.cx;
            ForTrialData.cy = obj.cy;
            ForTrialData.stimuli  = obj.stimuli;
            
        end
        
         
        function prepare_draw(obj,screenInfo)
            
            
            obj.stimuli = [];
            
            obj.frames = 0;
            
            
            
            
            ppd = screenInfo.ppd;
            
            %rect positions
        
            h_px = ppd*obj.square_height_deg;
            w_px = ppd*obj.square_width_deg;
            
            
            rect = [];
            for i=1:obj.nrows
                yini = h_px*(i-1);
                xini = 0;
                for j=1:obj.ncols
                    rect = [rect; xini, yini, xini+w_px, yini+h_px];
                    xini = xini + w_px;%for next one
                end
            end
            
            rect(:,1) = rect(:,1) - w_px*obj.ncols/2 + obj.cx*ppd + screenInfo.center(1);
            rect(:,3) = rect(:,3) - w_px*obj.ncols/2 + obj.cx*ppd + screenInfo.center(1);
            rect(:,2) = rect(:,2) - h_px*obj.nrows/2 + obj.cy*ppd + screenInfo.center(2);
            rect(:,4) = rect(:,4) - h_px*obj.nrows/2 + obj.cy*ppd + screenInfo.center(2);
            
            
            obj.pars.rect = rect; %rects in pixels, not centered at true location
            
%             rseed = obj.rseed;
%             
%             % SEED THE RANDOM NUMBER GENERATOR ... if "[]" is given, reset
%             % the seed "randomly"... this is for VAR/NOVAR conditions
%             % CHANGE THIS TO PERSISTENT SEED !!!!!!
%             if ~isempty(rseed) && length(rseed) == 1
%                 rstream = RandStream(obj.rand_algorithm,'Seed',rseed);
%             else
%                 rseed = sum(100*clock);
%                 rstream = RandStream(obj.rand_algorithm,'Seed',rseed);
%             end
%             obj.rstream = rstream;
%             obj.rseed = rseed;
%             
            
        end
        

        
        function draw(obj,screenInfo,rstream)
            
            obj.frames = obj.frames + 1;
            
            curWindow = screenInfo.curWindow;
            
            if mod(obj.frames,obj.inter_frames_interval)==1
                lum = randn(rstream,obj.nrows*obj.ncols,1)*obj.std_lum+obj.mean_lum; % improve base on gamma, etc.
                lum = clip(lum,0,1);%blabla
                obj.vars_for_draw.last_lum = lum;
            else
                lum = obj.vars_for_draw.last_lum;
            end
            colores = repmat(lum,1,3)*255;
            
            
            obj.stimuli(obj.frames).lum      = lum;
            
            Screen('BlendFunction', curWindow, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            Screen('FillRect', screenInfo.curWindow, colores', obj.pars.rect');
            
%             Screen(curWindow, 'DrawLines', xy ,obj.pars_exp.LineWidth ,...
%                 obj.pars_exp.LINES_color,screenInfo.center ,1);
            
        end
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

