function fit_results = fit_gonogo_laplace(DCM,plot)
DCM        = inversion_gonogo_laplace(DCM);   % Invert the model

%% 6.3 Check deviation of prior and posterior means & posterior covariance:
%==========================================================================

%--------------------------------------------------------------------------
% re-transform values and compare prior with posterior estimates
%--------------------------------------------------------------------------
field = fieldnames(DCM.M.pE);
for i = 1:length(field)
    if strcmp(field{i},'alpha_win') || strcmp(field{i},'alpha_loss')
        posterior.(field{i}) = 1/(1+exp(-DCM.Ep.(field{i})));
    elseif strcmp(field{i},'zeta')
        posterior.(field{i}) = 1/(1+exp(-DCM.Ep.(field{i})));       
    elseif strcmp(field{i},'T')
        posterior.(field{i}) = 1.5*exp(DCM.Ep.(field{i})) / (exp(DCM.Ep.(field{i}))+1);
    elseif strcmp(field{i},'beta') || strcmp(field{i},'a') || strcmp(field{i},'rs') || ...
        strcmp(field{i},'la') || strcmp(field{i},'pi_win') || strcmp(field{i},'pi_loss')
        posterior.(field{i}) = exp(DCM.Ep.(field{i})); 
    else
        fprintf("Warning: Was not expecting this prior/posterior field name. See fit_gonogo_laplace");
        field{i}
        posterior.(field{i}) = exp(DCM.Ep.(field{i}));
    end
end
params = posterior;
prior = DCM.M.priors;
% make sure the params that are not being fit are still passed into
% the likelihood function and loaded into priors
priors_names = fieldnames(prior);
for i = 1:length(priors_names)
    if ~isfield(params, priors_names{i})
        params.(priors_names{i}) = prior.(priors_names{i});
    end
end

[lik,latents] = likfun_gonogo(params, DCM.U,DCM.use_ddm);
if plot
    model_output.action_probabilities = latents.action_probabilities;
    model_output.observations = latents.r;
    model_output.choices = latents.c;
    model_output.P = latents.P;
    states_block = latents.trial_type;
    plot_gonogo(model_output,states_block);
end

avg_action_probability = mean(latents.action_probabilities);
fit_results.avg_action_probability = avg_action_probability;
fit_results.model_accuracy = sum(latents.action_probabilities > .5)/length(latents.action_probabilities);
fit_results.latents = latents;
fit_results.prior = prior;
fit_results.posterior = posterior;
fit_results.task_data = DCM.U;
fit_results.F = DCM.F;
fit_results.Cp = DCM.Cp;
fit_results.pC = DCM.pC;








