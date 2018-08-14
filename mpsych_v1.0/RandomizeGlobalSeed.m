function RandomizeGlobalSeed()

ss = RandStream('mt19937ar','Seed',sum(100*clock));
if ismethod('RandStream','setGlobalStream')
    RandStream.setGlobalStream(ss); %instalar matlab mas nuevo !!!
else
    RandStream.setDefaultStream(ss); %instalar matlab mas nuevo !!!
end