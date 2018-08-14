classdef AudioPlayClass < handle
    properties
        dat
    end
    
    methods
        function obj = AudioPlayClass(varargin)
            preloadfilenames = {};
            for i=1:length(varargin)
                if isequal(varargin{i},'files')
                    preloadfilenames = varargin{i+1};
                end
            end
            
            % Perform basic initialization of the sound driver:
            InitializePsychSound;
            
            
            %preload algunos sonidos
            for i=1:length(preloadfilenames)
                obj.dat(i).name = preloadfilenames{i};
                pahandle = obj.makeSound(preloadfilenames{i});
                obj.dat(i).pahandle = pahandle;
            end
            
        end
        
        function stop(obj)
            % % Stop playback:
            % PsychPortAudio('Stop', pahandle);
            
            
        end
        function close(obj)
            PsychPortAudio('Close');
        end
        
        function pahandle = makeSound(obj,wavfilename)
            if exist('audioread','file')
                [y, freq] = audioread(wavfilename);
            else
                [y, freq] = wavread(wavfilename);
            end
            wavedata = y';
            nrchannels = size(wavedata,1); % Number of rows == number of channels.
            
            
            % Make sure we have always 2 channels stereo output.
            % Why? Because some low-end and embedded soundcards
            % only support 2 channels, not 1 channel, and we want
            % to be robust in our demos.
            if nrchannels < 2
                wavedata = [wavedata ; wavedata];
                nrchannels = 2;
            end
            
%             % Perform basic initialization of the sound driver:
%             InitializePsychSound;
            
            % Open the default audio device [], with default mode [] (==Only playback),
            % and a required latencyclass of zero 0 == no low-latency mode, as well as
            % a frequency of freq and nrchannels sound channels.
            % This returns a handle to the audio device:
            pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
            
            % Fill the audio playback buffer with the audio data 'wavedata':
            PsychPortAudio('FillBuffer', pahandle, wavedata);
            
        end
        
        function playSound(obj,wavfilename)
            
            ind = find(ismember({obj.dat.name},wavfilename));
            if isempty(ind)
                pahandle = obj.makeSound(wavfilename);
            else
                pahandle = obj.dat(ind).pahandle;
            end
            % seria mas rapido hacer todo esto solo al principio del script
            % !!
            
            % Read WAV file from filesystem:
            
            
            % Start audio playback for 'repetitions' repetitions of the sound data,
            % start it immediately (0) and wait for the playback to start, return onset
            % timestamp.
            PsychPortAudio('Start', pahandle, 1, 0, 1);
            
        end
    end
end
