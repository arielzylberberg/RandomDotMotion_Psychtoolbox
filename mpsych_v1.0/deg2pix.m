function pix = deg2pix(deg,screenInfo)
    pix = deg*screenInfo.ppd;
end