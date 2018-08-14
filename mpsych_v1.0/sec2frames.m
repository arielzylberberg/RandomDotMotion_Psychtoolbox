function nframes = sec2frames(dur,screenInfo)
    %dur in seconds
    nframes = dur/(screenInfo.frameDur/1000);
    nframes = ceil(nframes);
end