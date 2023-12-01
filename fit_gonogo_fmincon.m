function results = fit_gonogo_fmincon(data)
    
    % Fit RL-DDM model to data from a Go/NoGo task.
    %
    % USAGE: results = fit_gonogo(data)
    %
    % INPUTS:
    %   data - [S x 1] data structure, where S is the number of subjects; see likfun_bandit for more details
    %
    % OUTPUTS:
    %   results - see mfit_optimize for more details
    %
    % Sam Gershman, Jun 2016
    
    % create parameter structure
    
    % drift rate go bias weight
    param(1).name = 'b1';
    param(1).logpdf = @(x) 0;  % uniorm prior
    param(1).lb = -20; % lower bound
    param(1).ub = 20;   % upper bound
    
    % drift rate differential action value weight
    % perhaps make this 0 to 20?
    param(2) = param(1);
    param(2).name = 'b2';
    param(2).lb = -20; % lower bound
    param(2).ub = 20;   % upper bound
    
    % Pavlovian bias  for win trials
    param(3).name = 'w1';
    param(3).logpdf = @(x) 0;  % uniorm prior
    param(3).lb = -20; % lower bound
    param(3).ub = 20;   % upper bound
    
    
    % Pavlovian bias for lose trials
    param(4).name = 'w2';
    param(4).logpdf = @(x) 0;  % uniorm prior
    param(4).lb = -20; % lower bound
    param(4).ub = 20;   % upper bound
    
    % boundary separation / decision threshold
    param(5).name = 'a';
    param(5).logpdf = @(x) 0;
    param(5).lb = 1e-3;
    param(5).ub = 20;
    
    % learning rate for win trials
    param(6).name = 'alpha_win';
    param(6).hp = [1.2 1.2];    % hyperparameters of beta prior
    param(6).logpdf = @(x) sum(log(betapdf(x,param(6).hp(1),param(6).hp(2))));
    param(6).lb = 0;
    param(6).ub = 1;
    
    % learning rate for loss trials
    param(7).name = 'alpha_loss';
    param(7).hp = [1.2 1.2];    % hyperparameters of beta prior
    param(7).logpdf = @(x) sum(log(betapdf(x,param(7).hp(1),param(7).hp(2))));
    param(7).lb = 0;
    param(7).ub = 1;

    % non-decision time
    param(8).name = 'T';
    param(8).logpdf = @(x) 0;
    param(8).lb = 0;
    param(8).ub = 1.5;
    
    % fit model
    f = @(x,data) likfun_gonogo(x,data,false);    % log-likelihood function
    results = mfit_optimize(f,param,data);
    
    % get P and drift rate with best params
   [lik, latents] = likfun_gonogo(results.x,data,true);
   results.P = latents.P;
   results.v = latents.v;