function [lik, latents] = likfun_gonogo(x,data, fitted_params)
    rng(23);
    % Likelihood function for Go/NoGo task.
    
    % USAGE: [lik, latents] = likfun_gonogo(x,data)
    %
    % INPUTS:
    %   x - parameters:
    %      
    %   data - structure with the following fields
               % rt
               % trial_type
               % c (choices)
               % r (rewards)
    %           
    %
    % OUTPUTS:
    %   lik - log-likelihood
    %   latents - structure with the following fields:
    %           .v - [N x 1] drift rate
    %           .P - [N x 1] probability density of Go
    %           .RT_mean - [N x 1] mean response time for Go
    %
    % Sam Gershman, Nov 2015
    
    % if fitted_params isn't passed in, initialize to false because not
    % dealing with fitted params
    if nargin < 3
        fitted_params = false;
    end
    
    
    % set parameters
    if ~isstruct(x)
        beta = x(1);          % go bias (affects drift rate)
        zeta = x(2);          % differential action value weight (affects drift rate)
        pi_win = x(3);          % pav bias for win trials
        pi_loss = x(4);          % pav bias for lose trials
        a =  x(5);          % boundary separation (i.e. decision threshold)
        alpha_win = x(6);   % learning rate for win trials (scales prediction error)
        alpha_loss = x(7);   % learning rate for loss trials (scales prediction error)
        T = x(8);           % non-decision time
        rs = x(9);
        la = x(10);
    else
        beta = x.beta;
        zeta = x.zeta;
        pi_win = x.pi_win;
        pi_loss = x.pi_loss;
        a = x.a;
        alpha_win = x.alpha_win;
        alpha_loss = x.alpha_loss;
        T = x.T;
        rs = x.rs;
        la = x.la;
    end
        
    % initialization
    lik = 0; 
   % data.rt = max(eps,data.rt - T);

    % state/action mapping to value
    Q = zeros(4,2);
    % state mapping to value
    V = zeros(4,1);
    mx = 1.5 - T;  % max reaction time is total trial time - non decision time
    states = data.trial_type;
    
    for t = 1:data.N
        
        % data for current trial
        c = data.c(t)+1;            % choice: 1 for no go, 2 for go
        r = data.r(t);              % reward: 0,1,-1
        s = states(t);              % trial type: 1 for go to win, 2 for go to avoid losing
                                    % 3 for no go to win, 4 for no go to avoid losing
  
        
        % calculate pavlovian influence
        if s == 1 || s == 3
            pav = pi_win*V(s);
        % adjust starting point for avoid losing condition
        elseif s == 2 || s == 4
            pav = pi_loss*V(s);
        end
                                    
        % drift rate
        v = zeta*(beta +(Q(s,2)-Q(s,1))+ pav);
        
        % accumulate log-likelihod
        % if fitting data
        if ~isnan(data.rt)
            % Go response
            if c == 2 
                % Wiener first passage time distribution calculates probability density that
                % the diffusion process hits the lower boundary at data.rt(t) - T. 
                % We pass in negative drift rate so lower boundary becomes "go"
                P = wfpt(data.rt(t)-T,-v,a);  
                % to get the action probability of hitting the go boundary
                action_probability = integral(@(y) wfpt(y,-v,a),0,mx);
                
            % NoGo response
            else
                % probability of hitting nogo boundary
                P = integral(@(y) wfpt(y,v,a),0,mx);
                action_probability = P;
            end
            
        else
            % simulating data
            % get probability of hitting go boundary during entire trial
            % (1.5 seconds)
            prob_go = integral(@(y) wfpt(y,-v,a),0,mx);
            action_probs = [1-prob_go prob_go];
            c = randsample(1:2, 1, true, action_probs);
            action_probability = action_probs(c);
            P = action_probability;
            % create reward matrix for 4 trial types: GTW, GAL, NGW,
            % NGAL
            rewardMatrix = [0, 1; -1, 0; 0, 1; -1, 0]; 
            if s == 1 || s ==2
                did_correct_choice = c == 2;
            elseif s == 3 || s ==4
                did_correct_choice = c == 1;
            end
            % prob_win is 80% if did correct thing, 20% otherwise
            prob_win = 0.2 + 0.6 * did_correct_choice;
            r = randsample(rewardMatrix(s,:), 1, true,[(1-prob_win) prob_win]); 
            
        end
        
        
       
        % let's plot how well the function does
        % Define the time range
%         if (t == 160 | t == 140 | t == 120 | t == 100 | t == 80 | t == 60) && fitted_params
%             z = 0:0.01:mx; % Time from 0 to 2 seconds in 0.01 second increments
% 
%             % Preallocate array for PDF values
%             pdf_values = zeros(size(z));
% 
%             % Compute the PDF for each time value
%             for i = 1:length(z)
%                 pdf_values(i) = wfpt(z(i), -v, a);
%             end
% 
%             % Plot the PDF
%             figure;
%             plot(z, pdf_values);
%             hold on; % Keep the current plot
%             line([data.rt(t) data.rt(t)], ylim, 'Color', 'red', 'LineWidth', 2);
%             hold off;
%             xlabel('Time (s)');
%             ylabel('Probability Density');
%             title(['Wiener Diffusion Model PDF at t = ', num2str(t)]);
% 
%         end
%         
        
     
        
        if P < 0
            fprintf("Negative probability density calculated!");
        end


        if isnan(P) || P==0; P = realmin; end % avoid NaNs and zeros in the logarithm
        lik = lik + log(P);
        
        % update values
        % if win trial
        if s == 1 || s == 3
            Q(s,c) = Q(s,c) + alpha_win*(r*rs - Q(s,c));
            V(s) = V(s) + alpha_win*(r*rs -V(s));
        % if loss trial
        elseif s == 2 || s == 4
            Q(s,c) = Q(s,c) + alpha_loss*(r*la - Q(s,c));
            V(s) = V(s) + alpha_loss*(r*la - V(s));
        end

         
        
        % store latent variables
        if nargout > 1
            latents.v(t,1) = v;
            %latents.P(t,1) = 1/(1+exp(-a*v));
            %latents.RT_mean(t,1) = (0.5*a/v)*tanh(0.5*a*v)+T;
            latents.P(t,1) = P;
            latents.action_probabilities(t) = action_probability;
            latents.r(t) = r;
            latents.c(t) = c;
            latents.rt = data.rt;
            latents.trial_type = data.trial_type;
            
        end
        
    end
    