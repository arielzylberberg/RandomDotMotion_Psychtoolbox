function filename = createFileName(subject,nameExtension,TASK_ID)

if nargin<3
    TASK_ID = nan;
end

dt = datestr(now,'yyyy_mm_dd_HH_MM_SS');

if isnan(TASK_ID)
    filename = [subject,'_',dt,'_',nameExtension,'.mat'];
else
    t = num2str(TASK_ID);
    while length(t)<4
        t = ['0',t];
    end
    filename = [t,'_',subject,'_',dt,'_',nameExtension,'.mat'];
end

