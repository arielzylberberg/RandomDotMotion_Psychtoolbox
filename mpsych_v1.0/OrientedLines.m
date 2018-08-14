classdef OrientedLines < handle
    properties
        pars_exp
        vars_for_draw
        dir
        signal
        stdev
        meanOrientation
        stimuli
        
        uni_signal = [0:3]*pi/240;
        uni_dir    = [-1, 1];
        uni_stdev  = [pi/32, pi/24, pi/16];
        
        frames
        rseed
        rand_algorithm = 'mt19937ar'
        rstream
        
    end
    
    
    methods
        
        % defined here
        function obj = OrientedLines(varargin)
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
            ForTrialData.stdev           = obj.stdev;
            ForTrialData.dir            = obj.dir;
            ForTrialData.signal          = obj.signal;
            ForTrialData.stimuli         = obj.stimuli;
            
        end
        
        function init_exp(obj,screenInfo)
            
            ppd = screenInfo.ppd;
            
            obj.pars_exp.annulusRadius          = 2.5 * ppd;
            obj.pars_exp.referenceDist          = 3.3 * ppd;
            obj.pars_exp.referenceLength        = 1.2 * ppd;
            obj.pars_exp.N                      = 4;
            obj.pars_exp.barLength              = 1.2 * ppd;
            obj.pars_exp.LineWidth              = 2;
            obj.pars_exp.LINES_color            = 255*ones(1,3);
            
            
            
        end
        
        function prepare_draw(obj,screenInfo)
            
            %             obj.vars_for_draw = struct('Ls',Ls,'ss',ss,'loopi',loopi,'coh',coh,'coh_std',coh_std,...
            %                 'ndots',ndots,'dxdy',dxdy,'d_ppd',d_ppd,'apRect',apRect,...
            %                 'dotSize',dotSize,'center',center,'rotationMat',rotationMat);
            
            obj.meanOrientation = -pi/2 + obj.dir * obj.signal;
            
            obj.stimuli = [];
            
            obj.frames = 0;
            
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
            
            
        end
        
        function draw_reference(obj,screenInfo)
            curWindow = screenInfo.curWindow;
            Screen(curWindow,'DrawLine', [0,0,255], screenInfo.center(1), ...
                screenInfo.center(2) + obj.pars_exp.referenceDist, screenInfo.center(1), ...
                screenInfo.center(2) + obj.pars_exp.referenceDist + obj.pars_exp.referenceLength, 2);
            Screen(curWindow,'DrawLine', [0,0,255], screenInfo.center(1), ...
                screenInfo.center(2) - obj.pars_exp.referenceDist, screenInfo.center(1), ...
                screenInfo.center(2) - obj.pars_exp.referenceDist - obj.pars_exp.referenceLength, 2);
        end
        
        function draw(obj,screenInfo)
            
            obj.frames = obj.frames + 1;
            
            curWindow = screenInfo.curWindow;
            
            [xy,alfa] = randomOrientedBars(obj.rstream,obj.pars_exp.annulusRadius,...
                obj.pars_exp.N,obj.pars_exp.barLength,...
                obj.meanOrientation, obj.stdev);
            
            obj.stimuli(obj.frames).xy      = xy;
            obj.stimuli(obj.frames).alfa    = alfa;
            
            Screen('BlendFunction', curWindow, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            Screen(curWindow, 'DrawLines', xy ,obj.pars_exp.LineWidth ,...
                obj.pars_exp.LINES_color,screenInfo.center ,1);
            
        end
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xy,angles] = randomOrientedBars(rstream,annulusRadius,N,barLength,meanOrientation,dev)
% the output should be plotted with Screen('DrawLines')
% 31/01/12
% To correct:
% (a) uniform density and number of lines
% (b) check whether mean orientation works OK
% (c) adjust the amplitude of the noise


% sample the orientations
% gaussian sampling
% alfa        = dev*randn(4*N,1) + meanOrientation; % here dev is the std deviation
%uniform
% alfa        = dev*((rand(4*N,1)-0.5)*2) + meanOrientation; % here dev is the 1/2 full range

% sampleo solo positivos
alfa        = dev*(rand(rstream,N/2,1)); % here dev is the 1/2 full range
alfa        = [alfa;-alfa]; % compensan la orientacion
alfa        = alfa + meanOrientation;% rotacion

% me quedo con N posiciones dentro del circulo
needData = true;
% screen('closeall');
while needData
    
    % mas de lo necesario
    x_ini = annulusRadius * 2*(rand(rstream,4*N,1)-0.5);
    y_ini = annulusRadius * 2*(rand(rstream,4*N,1)-0.5);
    
    
    inds = find((x_ini.^2 + y_ini.^2) < annulusRadius ^ 2);
    
    %     inds = find((x_ini.^2 + y_ini.^2) < annulusRadius ^ 2) & ...
    %           ((x_end.^2 + y_end.^2) < annulusRadius ^ 2);
    
    if length(inds)<N
        needData = true;
    else
        needData = false;
        
        x_ini   = x_ini(inds(1:N));
        y_ini   = y_ini(inds(1:N));
        x_end   = x_ini + cos(alfa) * barLength;
        y_end   = y_ini + sin(alfa) * barLength;
        
    end
end

angles = alfa;

x_temp  = [x_ini x_end]';
y_temp  = [y_ini+barLength/2 y_end+barLength/2]';

xy      = [x_temp(:) y_temp(:)]';

end




