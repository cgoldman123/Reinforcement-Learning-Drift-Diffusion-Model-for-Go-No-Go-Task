function model_output = sim_gonogo(gen_params)
    % Read in states from subject AA111 game
    load('states_block.mat');
    data.N = 160;
    data.rt = nan(1, 160);
    data.c = nan(1, 160);
    data.r = nan(1, 160);
    data.trial_type = states_block;
    [lik, latents] = likfun_gonogo(gen_params,data);
    model_output.action_probabilities = latents.action_probabilities;
    model_output.observations = latents.r;
    model_output.choices = latents.c;
    model_output.P = latents.P;
    plot_gonogo(model_output, states_block);
    
end