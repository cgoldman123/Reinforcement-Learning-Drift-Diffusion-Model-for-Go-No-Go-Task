function [DCM] = inversion_gonogo_laplace(DCM)

% MDP inversion using Variational Bayes
%
% Expects:
%--------------------------------------------------------------------------
% DCM.MDP   % MDP structure specifying a generative model
% DCM.field % parameter (field) names to optimise
% DCM.data  % struct of behavioral data
%
% Returns:
%--------------------------------------------------------------------------
% DCM.M     % generative model (DCM)
% DCM.Ep    % Conditional means (structure)
% DCM.Cp    % Conditional covariances
% DCM.F     % (negative) Free-energy bound on log evidence
% 
% This routine inverts (cell arrays of) trials specified in terms of the
% stimuli or outcomes and subsequent choices or responses. It first
% computes the prior expectations (and covariances) of the free parameters
% specified by DCM.field. These parameters are log scaling parameters that
% are applied to the fields of DCM.MDP. 
%
% If there is no learning implicit in multi-trial games, only unique trials
% (as specified by the stimuli), are used to generate (subjective)
% posteriors over choice or action. Otherwise, all trials are used in the
% order specified. The ensuing posterior probabilities over choices are
% used with the specified choices or actions to evaluate their log
% probability. This is used to optimise the MDP (hyper) parameters in
% DCM.field using variational Laplace (with numerical evaluation of the
% curvature).
%
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dcm_mdp.m 7120 2017-06-20 11:30:30Z spm $

% OPTIONS
%--------------------------------------------------------------------------
ALL = false;

% prior expectations and covariance
%--------------------------------------------------------------------------
prior_variance = 2^-1;

% Set up DCM
%--------------------------------------------------------------------------


for i = 1:length(DCM.field)
    field = DCM.field{i};
    try
        param = DCM.MDP.(field);
        param = double(~~param);
    catch
        param = 1;
    end
    if ALL
        pE.(field) = zeros(size(param));
        pC{i,i}    = diag(param);
    else
        if strcmp(field,'prior_a')
            pE.(field) = DCM.MDP.prior_a;             % don't transform prior_a
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'rs')
            pE.(field) = log(DCM.MDP.rs);             % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'la')
            pE.(field) = log(DCM.MDP.la);             % in log-space (to keep positive)
            pC{i,i}    = prior_variance;      
        elseif strcmp(field,'pi_win')
            pE.(field) = log(DCM.MDP.pi_win);             % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'pi_loss')
            pE.(field) = log(DCM.MDP.pi_loss);             % in log-space (to keep positive)
            pC{i,i}    = prior_variance;        
        elseif strcmp(field,'zeta')
            pE.(field) = log(DCM.MDP.zeta/(1-DCM.MDP.zeta));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'eta_win')
            pE.(field) = log(0.5/(1-0.5));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'eta_loss')
            pE.(field) = log(0.5/(1-0.5));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'beta')
            pE.(field) = log(DCM.MDP.beta);                % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'a')
            pE.(field) = log(DCM.MDP.a);                % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'alpha_win')
            pE.(field) = log(DCM.MDP.alpha_win/(1-DCM.MDP.alpha_win));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'alpha_loss')
            pE.(field) = log(DCM.MDP.alpha_loss/(1-DCM.MDP.alpha_loss));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'T')
            pE.(field) = log(DCM.MDP.T/(1.5-DCM.MDP.T));   % BOUND BETWEEN 0 AND 1.5
            pC{i,i}    = prior_variance;
        else
            fprintf("Warning: one of parameters not being properly transformed. See inversion_gonogo_laplace");
            pE.(field) = 0;
            pC{i,i}    = prior_variance;
        end
    end
end

pC      = spm_cat(pC);

% model specification
%--------------------------------------------------------------------------
M.L     = @(P,M,U,Y)spm_mdp_L(P,M,U,Y);  % log-likelihood function
M.pE    = pE;                            % prior means (parameters)
M.pC    = pC;                            % prior variance (parameters)
M.use_ddm = DCM.use_ddm;                 % indicate if want to use ddm
M.priors = DCM.MDP;

% Variational Laplace
%--------------------------------------------------------------------------
[Ep,Cp,F] = spm_nlsi_Newton(M,DCM.U, DCM.Y);

% Store posterior densities and log evidnce (free energy)
%--------------------------------------------------------------------------
DCM.M   = M;
DCM.Ep  = Ep;
DCM.Cp  = Cp;
DCM.F   = F;
DCM.U = DCM.U;
DCM.pC = pC;


return

function L = spm_mdp_L(P,M,U,Y)
% log-likelihood function
% FORMAT L = spm_mdp_L(P,M,U,Y)
% P    - parameter structure
% M    - generative model
% data - inputs and responses
%__________________________________________________________________________

if ~isstruct(P); P = spm_unvec(P,M.pE); end

% retransform params
field = fieldnames(M.pE);
for i = 1:length(field)
    if strcmp(field{i},'prior_a')
        params.(field{i}) = P.(field{i});
    elseif strcmp(field{i},'zeta')
        params.(field{i}) = 1/(1+exp(-P.(field{i})));        
    elseif strcmp(field{i},'rs')
        params.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'la')
        params.(field{i}) = exp(P.(field{i}));   
        
    elseif strcmp(field{i},'pi_win')
        params.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'pi_loss')
        params.(field{i}) = exp(P.(field{i}));      
        
    elseif strcmp(field{i},'eta_win')
        params.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'eta_loss')
        params.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'beta')
        params.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'a')
        params.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'alpha_win')
        params.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'alpha_loss')
        params.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'T')
        params.(field{i}) = 1.5*exp(P.(field{i})) / (exp(P.(field{i}))+1);
    else
        fprintf("Warning: one of parameters not being properly transformed. See inversion_gonogo_laplace");
        params.(field{i}) = exp(P.(field{i}));
    end
end

% make sure the params that are not being fit are still passed into
% the likelihood function
priors_names = fieldnames(M.priors);
priors = M.priors;
for i = 1:length(priors_names)
    if ~isfield(params, priors_names{i})
        params.(priors_names{i}) = priors.(priors_names{i});
    end
end

L = likfun_gonogo(params,U,M.use_ddm);
if (~isreal(L))
    fprintf("NOT REAL");
end
%L = L/100;
  

clear('MDP')
    

fprintf('LL: %f \n',L)

