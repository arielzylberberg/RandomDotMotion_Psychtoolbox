classdef QuerySubjectClass < handle
    properties
       subject
       training
       expcode
       extra = []
       
    end
    
    methods
        function obj = QuerySubjectClass(varargin)
            
            extra_fields = [];
            for i=1:length(varargin)
                if isequal(varargin{i},'extra_fields')
                    extra_fields = varargin{i+1};
                end
            end
            
            prompt     = {'participant','training','exp_code'}; % prompt for the filename
            dlg_title  = 'Filename'; % title of the input dialog box
            num_lines  = 1; % number of input lines
            default    = {'Xtest','0','0'}; % default filename
            
            for i=1:length(extra_fields)
                prompt{end+1}  = extra_fields(i).str;
                default{end+1} = num2str(extra_fields(i).default);
            end
            
            savestr    = inputdlg(prompt,dlg_title,num_lines,default);
            
            obj.subject    = savestr{1};
            obj.training   = str2double(savestr{2});
            obj.expcode    = str2double(savestr{3});
            
            for i=1:length(extra_fields)
                str  = extra_fields(i).str;
                obj.extra.(str)  = savestr{3+i};
            end
            
            % si es de entrenamiento, cambia el nombre
            if obj.training~=0
                obj.subject = [obj.subject,'_training_expcode',num2str(obj.expcode)];
            end
            
        end
        
        function ForSessionData = sessionInfo(obj)
            ForSessionData = struct(obj);
        end
        
    end
end

