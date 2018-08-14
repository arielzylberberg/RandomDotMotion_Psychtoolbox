function y = sampleCondition(pars)

ncond               = pars.nconditions;
conditions_history  = pars.conditions_history;
balance_every       = pars.balance_every;

%number of trials completed for 
%each condition
uni_cond = 1:ncond;
R = nan(ncond,1);
for i=1:ncond
    R(i) = sum(conditions_history==uni_cond(i));
end

n = length(conditions_history);

epsilon = 0.0000001;
t = ceil(n/balance_every+epsilon);
req_tr_per_cond = balance_every*t/ncond;%asume uniforme

faltan = req_tr_per_cond - R;

%samplear condiciones de acuerdo a los trials 
%que faltan
faltan(faltan<0) = 0;
y = sampleWeightVector(faltan,1);
