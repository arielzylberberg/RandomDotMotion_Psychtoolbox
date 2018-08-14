classdef BlocksClass < handle
    properties
        datafile
        file_id
        scaling
        datafolder
        colorfill = [0 127 0 255]
        colorframe = [0 255 255 255]
        frame
        dframe = 1
        espejar
        
        vertices
        vertices_from_file
        times
        block_id
        fr
    end
    
    methods
        function obj = BlocksClass(datafolder)
            obj.datafolder = datafolder;
            
        end
        
        function getData(obj,file_id)
            obj.file_id  = file_id;
            obj.datafile = fullfile(obj.datafolder,['dynamics_config',num2str(file_id),'.txt']);
            dat = load(obj.datafile);
            obj.vertices_from_file = dat(:,end-7:end);
            obj.times    = dat(:,2);
            obj.block_id = dat(:,1);
            u = unique(obj.times);
            obj.fr = round(obj.times/(u(2)-u(1)));
            
        end
        
        function prepare_draw(obj,scaling,dframe,espejar)
            obj.frame = 0;
            obj.scaling = scaling;
            obj.vertices = round(obj.vertices_from_file * obj.scaling);
            obj.dframe = dframe;
            obj.espejar = espejar;
            
        end
        
        function isEOF = EOF(obj)
            isEOF = all(obj.fr<(obj.frame+obj.dframe));
        end
        
        function draw(obj,screenInfo)
            
            curWindow = screenInfo.curWindow;
            cx = screenInfo.center(1);
            cy = screenInfo.center(2);
            
            obj.frame = obj.frame + obj.dframe;
            
%             inds = find(d(:,2)==t(i));
            inds = obj.fr == obj.frame;
%             find(inds)
            
            %     ppm = 7.5;
            %     x = round(vert(inds,[1:2:end 1])*ppm);
            %     y = -(round(vert(inds,[2:2:end 2])*ppm));
            
            x = obj.vertices(inds,[1:2:end 1]);
            y = -obj.vertices(inds,[2:2:end 2]);
            
            displace_y = 50;
            
            delta_x = -(x(1,1) + x(1,2))/2 + cx;
            delta_y = -max(y(1,:)) + cy + displace_y;
            
            x = x + delta_x;
            
            if (obj.espejar==1)
                x = -1*(x-cx)+cx;
            end
            
            y = y + delta_y;
            
%             Screen('FillRect',curWindow,[0 0 0])
            
            xline=[]; yline=[];
            for j=1:size(x,1)
                Screen('FillPoly', curWindow, obj.colorfill, [x(j,:)' y(j,:)'],1);
%                 Screen('FramePoly', curWindow, obj.colorframe, [x(j,:)' y(j,:)'],1);
                xline = [xline x(j,[1 2 2 3 3 4 4 5])];
                yline = [yline y(j,[1 2 2 3 3 4 4 5])];
            end
             xy = [xline; yline];
%             
%             %doesn't seem to work much better than the FramePoly in 
%             %terms of smoothing
             Screen('BlendFunction', screenInfo.curWindow, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
             Screen('DrawLines', curWindow, xy,1.2,obj.colorframe,[],1);
            
            
        end
        
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
            
        end
        
        function ForTrialData = trialInfo(obj)
            ForTrialData.file_id = obj.file_id;
            ForTrialData.espejar = obj.espejar;
            ForTrialData.vertices = obj.vertices;
        end
        
        
    end
end