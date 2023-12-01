function [outcomes, gen_choices] = sim_gonogo(gen_params)

    
    % Read in states from subject AA111 game
    load('states_block.mat');
    data.rt = NaN;
    
    MDP = likfun_gonogo(gen_params,data, true);
    GNG_plot(MDP, states_block);
    
    outcomes(:,1) = MDP.observations;
    outcomes(:,2) = states_block;
    gen_choices = MDP.choices';
end