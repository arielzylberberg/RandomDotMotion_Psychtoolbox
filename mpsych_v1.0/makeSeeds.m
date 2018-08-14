function seeds = makeSeeds(conditions,type,Nreps)
% function seeds = makeSeeds(conditions,type,Nreps)
%type=0: all seeds are unique
%type=1: Npass, depending of parameter Nreps
%type=2: half of the trials have the same seed, and half
% have random seeds

if nargin==3 && type~=1
    error('assume no repetitions')
end

if nargin<3
    Nreps = 1;
end

if any(size(conditions)==1)
    idx_conditions = conditions;
else
    % if is a matrix, compute the unique rows 
    % to determine
    [~,~,idx_conditions] = unique(conditions,'rows');
end


n = length(idx_conditions);

u = unique(idx_conditions);
r = Rtable(idx_conditions);

seeds = nan(size(idx_conditions));

if type==0
    seeds = randi(intmax,n,1);
    
elseif type==1
    if any(r==1)
        nn = ceil(n/Nreps);
        uni_seeds = randi(intmax,nn,1);
        ss = repmat(uni_seeds,1,Nreps);
        ss = ss(:);
        ss = shuffle(ss);
        ss = ss(1:n);
        seeds = ss;
        
    else
        for i=1:length(u)
            inds   = idx_conditions == u(i);
            nseeds = ceil(r(i)/Nreps);
            se = randi(intmax,nseeds,1);
            se = se(:);
            se = repmat(se,1,Nreps)';
            se = se(:);
            se = se(1:r(i));
            seeds(inds) = shuffle(se);
        end
    end
    
elseif type==2
    %     seeds = randi(intmax,n,1);
    repeated_seed = randi(intmax,1,1);
    seeds = randi(intmax,n,1); %unique seeds
    if any(r==1) %not repeated conditions
        inds  = shuffle(1:n);
        inds = inds(1:floor(n/2));
        seeds(inds) = repeated_seed; %repeated seeds
        
    else %conditions are repeated
        for i=1:length(u)
            inds   = shuffle(find(idx_conditions == u(i)));
            inds = inds(1:floor(r(i)/2));
            seeds(inds) = repeated_seed;
        end
        
    end
    
end

seeds = seeds(:);
