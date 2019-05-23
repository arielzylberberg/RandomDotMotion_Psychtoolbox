function main_dots_binary_VD()
% Runs the random-dot motion discrimination task (Shadlen-style dots). Variable-duration dots.

% Report decisions with "d" and "k" for left and right motion respectively,
% or with the eyes if an eyetracker is connected.

% Without an eyetracker, press the spacebar to simulate fixation
% acquisition

% written by Ariel Zylberberg (ariel.zylberberg@gmail.com)

%%
addpath('mpsych_v1.0/')
addpath('other_functions/')

TASK_ID = 10;

workspace
KbName('UnifyKeyNames');
extra_field.str = 'rotation_deg';
extra_field.default = 0;
query = QuerySubjectClass('extra_fields',extra_field);
rotation = str2double(query.extra.rotation_deg);

extension = mfilename;
extension = strrep(extension,'.mat','');
extension = strrep(extension,'main_','');
filename = createFileName(query.subject,extension,TASK_ID);

try
    
    %initialize the screen
    screenInfo = openExperiment();

    curWindow = screenInfo.curWindow;
    dontclear = screenInfo.dontclear;
    
    % set eyetracker
    Eye = EyeTrackerClass();
    if isequal(screenInfo.computer,'Ariels-MacBook-Pro.local')
        Eye.setPars('dummymode',1);
    end
    
    Mouse = MouseClass();
    
    % instantiate classes
    d = DotsClass(1);
    d.setPars(1,'dirSet', [0+rotation,180+rotation]);%anticlockwise
%     d.setPars(1,'cohStdSet',[0 256]);
    
    if query.training==1 && query.expcode==1
        d.setPars(1,'cohSet',[256,512]);
    end
    
    cx = screenInfo.center(1);
    cy = screenInfo.center(2);
    fixation = FixationClass(cx,cy,5,[255/2 255/2 255]);
    targets = TargetsClass();
    delta = deg2pix(9,screenInfo);%grados a pixels
    
    targets.add(cx+delta*cos(-rotation*2*pi/360),...
        cy+delta*sin(-rotation*2*pi/360),20,[255 0 0]);
    
    targets.add(cx+delta*cos((-rotation+180)*2*pi/360),...
        cy+delta*sin((-rotation+180)*2*pi/360),20,[255 0 0]);
    
    %sonido feedback
    Audio = AudioPlayClass('files',{'ding.wav','signoff.wav','secalert.wav','click.wav'});

    key = KeysClass();
    targets.asocToKey(1,'k')
    targets.asocToKey(2,'d')
    %     targets.asocToKey(3,'c')
    %     targets.asocToKey(4,'m')
    
    times = TimeClass('fix_on','fix_tar_on','dots_on','intertrial','show_choice',...
        'error_timeout','resp_maxtime','nochoice_timeout','fixbreak_timeout');
    
    %
    RandomizeGlobalSeed;
            
    %conditions block
    nTrialsPerCondition = 6;
    [cond,nTr,idx_conditions] = createFactorialTrialList({'coh',d.df{1}.cohSet,...
        'dir',d.df{1}.dirSet},...
        nTrialsPerCondition);
    req_target(cond.dir==(0+rotation))     = 1;
    req_target(cond.dir==(0+rotation+180)) = 2;
    
    %semillas
    seeds = makeSeeds(idx_conditions,1,2);
    
    % setapear el eye tracker
    Eye.setupEyetracker(screenInfo);
    
    %
    WaitSecs(3);
    
    %
    Mouse.Hide(screenInfo);
    
    % pasar a otro lado:
    Priority(MaxPriority(screenInfo.curWindow));
    
    %
    for iTr = 1:nTr
        
        done = 0;
        trial_result = '';
        correct     = nan;
        rt          = nan;
        choice      = nan;
        
        nextstep = 'wait_acq_fix';
        d.df{1}.setPars('coh',cond.coh(iTr),'dir',cond.dir(iTr),...
            'rseed',seeds(iTr));
        
        d.prepare_draw(screenInfo);
        
        % semillas globales, para que la duration sea igual si semilla
        % igual. Ojo.
        ss = RandStream('mt19937ar','Seed',d.df{1}.rseed+1);
        %             RandStream.setGlobalStream(ss);
        if ismethod('RandStream','setGlobalStream')
            RandStream.setGlobalStream(ss); %instalar matlab mas nuevo !!!
        else
            RandStream.setDefaultStream(ss); %instalar matlab mas nuevo !!!
        end
        
        times.sample('fix_on',       {'type',0,'min',0.5});
%         times.sample('fix_tar_on',
%         {'type',2,'min',0.3,'max',1,'mean',0.5});
        times.sample('fix_tar_on',   {'type',2,'min',0.4,'max',0.9,'mean',0.5});
%         times.sample('dots_on',
%         {'type',2,'min',1.2,'max',1.6,'mean',0.6});
        times.sample('dots_on',      {'type',2,'min',0.2,'max',0.9,'mean',0.6});
        times.sample('intertrial',   {'type',0,'min',1.0});
        times.sample('error_timeout',{'type',0,'min',1.0});
        times.sample('resp_maxtime', {'type',0,'min',10});
        times.sample('show_choice',  {'type',0,'min',0.1});
        times.sample('nochoice_timeout',{'type',0,'min',2.0});
        times.sample('fixbreak_timeout',{'type',0,'min',2.0});
        
        while ~done
            
            switch nextstep
                
                case 'wait_acq_fix'
                    disp('wait_acq_fix')
                    
                    Screen('FillRect', curWindow, screenInfo.bckgnd)
                    fixation.draw(screenInfo);
                    Screen('Flip', curWindow,0,dontclear);
                    %                     WaitSecs(times.dat.fix_on);
                    [ret, func_ret, waited_time] = WaitUntil(@fixation.fixAcquired, {screenInfo,Eye,key,Mouse}, 6, 0.001, curWindow, 1);
                    if ret==2 %too long
                        Eye.doCalibration();
                        nextstep = 'wait_acq_fix';
                    else
                        nextstep = 'fix_on';
                    end
                    
                case 'fix_on'
                    
                    disp('fix_on')
                    Screen('FillRect', curWindow, screenInfo.bckgnd)
                    fixation.draw(screenInfo);
                    Screen('Flip', curWindow,0,dontclear);
                    Eye.Message(nextstep)
                    
                    [ret, func_ret, waited_time] = WaitUntil(@fixation.lostFixation, {screenInfo,Eye,key,Mouse}, times.dat.fix_on, 0.001, curWindow, 1);
                    if ret==1 %perdio fijacion
                        nextstep = 'wait_acq_fix';
                    else
                        nextstep = 'fix_tar_on';
                    end
                    
                case 'fix_tar_on'
                    disp('fix_tar_on')
                    
                    Screen('FillRect', curWindow, screenInfo.bckgnd);
                    fixation.draw(screenInfo);
                    targets.draw(screenInfo);
                    Screen('Flip', curWindow,0,dontclear);
                    Eye.Message(nextstep)
                    
                    [ret, func_ret, waited_time] = WaitUntil(@fixation.lostFixation, {screenInfo,Eye,key,Mouse}, times.dat.fix_tar_on, 0.001, curWindow, 1);
                    
                    if ret==1 %perdio fijacion
                        nextstep = 'wait_acq_fix';
                    else
                        nextstep = 'dots_on_fix_dur';
                    end
                    
                case 'dots_on_fix_dur'
                    disp('dots_on_fix_dur')
                    
                    while d.df{1}.frames <= sec2frames(times.dat.dots_on,screenInfo)
                        Screen('FillRect', curWindow, screenInfo.bckgnd)
                        d.df{1}.draw(screenInfo);
                        fixation.draw(screenInfo);
                        targets.draw(screenInfo);
                        
                        vbl = Screen('Flip', curWindow,0,dontclear);
                        if d.df{1}.frames == 1
                            Eye.Message(nextstep);
                        end
                        if key.pressed() || fixation.lostFixation(screenInfo,Eye,key,Mouse)
                            trial_result = 'FIXBREAK';
                            break;
                        end
                    end
                    
                    if isequal(trial_result, 'FIXBREAK')
                        nextstep = 'invalid_trial';
                    else
                        nextstep = 'dots_off';
                    end
                
                case 'dots_off'
                    disp('dots_off')
                    Eye.Message(nextstep);
                    nextstep = 'get_response';    
                    
                case 'get_response'
                    disp(nextstep)
                    Eye.Message('response_allowed');
                    
                    if Eye.dummymode
                        Mouse.centerMouse(screenInfo);
                    end

                    t_resp_allowed = GetSecs();
                    mx = 0; my = 0;
                    while ~targets.tarSelected(screenInfo,Eye,key)
                          
                        Screen('FillRect', curWindow, screenInfo.bckgnd)
                        targets.draw(screenInfo);

                        [mx,my,mt] = Eye.getEyedata();
                        if Eye.dummymode && sqrt((mx-cx)^2+(my-cy)^2)>deg2pix(2.5,screenInfo)
                            Eye.ShowEyePosition(screenInfo);
                        end
                        
                        vbl = Screen('Flip', curWindow,0,dontclear);
                        if (vbl-t_resp_allowed) > times.dat.resp_maxtime
                            trial_result = 'NOCHOICE';
                            break;
                        end
                    end

                    if isequal(trial_result,'NOCHOICE')
                        Eye.Message('no choice');
                        rt = nan;
                        nextstep = 'invalid_trial';
                    else
                        rt = GetSecs() - t_resp_allowed;
                        Eye.Message('response_selected');
                        choice = targets.selTar;
                        correct = req_target(iTr) == choice;
                        if correct == 1
                            trial_result = 'CORRECT';
                        else
                            trial_result = 'WRONG';
                        end
                        nextstep = 'feedback_and_intertrial';
                    end
                    
                    %ahow the targets a little longer
                    Screen('FillRect', curWindow, screenInfo.bckgnd)
                    targets.draw(screenInfo);
                    Screen('Flip', curWindow,0,1);
                    WaitSecs(times.dat.show_choice)
                    
                    if key.abort
                        sca %mejorar
                    end
                    
                
                    
                case 'invalid_trial'
                    disp('invalid_trial')
                    
                    Eye.Message(nextstep)
                    Screen('FillRect', curWindow, screenInfo.bckgnd)
                    
                    % horizontally and vertically centered:
                    [nx, ny, bbox] = DrawFormattedText(curWindow, 'invalid trial', 'center', 'center',  [255 0 0]);
                    Screen('Flip', curWindow,0,dontclear);
                    WaitSecs(2);
                    
                    nextstep = 'feedback_and_intertrial';
                    
                case 'feedback_and_intertrial'
                    disp('feedback_and_intertrial')
                    
                    done = 1;
                    Eye.Message(nextstep)
                    
                    %pantalla negra
                    Screen('FillRect', curWindow, screenInfo.bckgnd)
                    Screen('Flip', curWindow,0,dontclear);
                    nextstep = 'wait_acq_fix';
                    
                    switch trial_result
                        case 'CORRECT'
                            Audio.playSound('ding.wav');
                            WaitSecs(times.dat.intertrial);
                            
                        case 'WRONG'
                            Audio.playSound('signoff.wav');
                            WaitSecs(times.dat.intertrial + times.dat.error_timeout);
                            
                        case 'FIXBREAK'
%                             Audio.playSound('secalert.wav');
                            WaitSecs(times.dat.intertrial + times.dat.fixbreak_timeout);
                        
                        case 'NOCHOICE'
%                             Audio.playSound('click.wav');
                            WaitSecs(times.dat.intertrial + times.dat.nochoice_timeout);
                            
                    end

                    
                    % que la clase indique que debe guardarse ej: trialData =
                    % obj.getTrialData(trialData);
                    trialData(iTr).given_resp = choice;
                    trialData(iTr).req_resp = req_target(iTr);
                    trialData(iTr).correct = correct;
                    trialData(iTr).rt = rt;
                    
                    trialData(iTr).trial_result = trial_result;
                    trialData(iTr).rdm1 = d.df{1}.trialInfo();
                    trialData(iTr).fix = fixation.trialInfo();
                    trialData(iTr).times = times.trialInfo();
                    trialData(iTr).TASK_ID = TASK_ID;
                    
                    eyeInfo = Eye.sessionInfo();
                    mouseInfo = Mouse.sessionInfo();
                    fixationInfo = fixation.sessionInfo();
                    targetsInfo = targets.sessionInfo();
                    keysInfo = key.sessionInfo();
                    dotInfo = d.sessionInfo();
                    queryInfo = query.sessionInfo();
                    
                    save(filename,'trialData','screenInfo',...
                        'eyeInfo','mouseInfo','fixationInfo','targetsInfo',...
                        'keysInfo','dotInfo','queryInfo','rotation');
                    
                    Eye.Message('trial_saved');
                    
                    targets.cleanForNextTrial();
                    key.cleanForNextTrial();
                    
            end
            
        end
    end
    Eye.StopAndGetFile(filename);
    Priority(0);
    sca
    Audio.close();
    
catch
    sca
    Priority(0);
    ple
    Audio.close();
    
end

clear screen

end
