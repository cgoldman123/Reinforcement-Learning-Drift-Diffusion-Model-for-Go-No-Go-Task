function [lik, latents] = likfun_gonogo(x,data, fitted_params)
    
    % Likelihood function for Go/NoGo task.
    
    % USAGE: [lik, latents] = likfun_gonogo(x,data)
    %
    % INPUTS:
    %   x - parameters:
    %       x(1) - drift rate go bias weight (b1)
    %       x(2) - drift rate differential action value weight (b2)
    %       x(3) - drift rate Pavlovian bias weight (b3)
    %       x(4) - learning rate for state-action values (alpha)
    %       x(5) - decision threshold (a)
    %       x(6) - non-decision time (T)
    %   data - structure with the following fields
    %           .c - [N x 1] choices
    %           .r - [N x 1] rewards
    %           .s - [N x 1] states
    %           .rt - [N x 1] response times
    %           .go - [N x 1] go trial indicator (1=Go, 0=NoGo)
    %           .C - number of choice options
    %           .N - number of trials
    %
    % OUTPUTS:
    %   lik - log-likelihood
    %   latents - structure with the following fields:
    %           .v - [N x 1] drift rate
    %           .P - [N x 1] probability of Go
    %           .RT_mean - [N x 1] mean response time for Go
    %
    % Sam Gershman, Nov 2015
    
    % if fitted_params isn't passed in, initialize to false because not
    % dealing with fitted params
    if nargin < 3
        fitted_params = false;
    end
    
    
    % set parameters
    b1 = x(1);          % go bias (affects drift rate)
    b2 = x(2);          % differential action value weight (affects drift rate)
    w1 = x(3);          % pav bias for win trials
    w2 = x(4);          % pav bias for lose trials
    a =  x(5);          % boundary separation (i.e. decision threshold)
    alpha_win = x(6);   % learning rate for win trials (scales prediction error)
    alpha_loss = x(7);   % learning rate for loss trials (scales prediction error)
    T = x(8);           % non-decision time
    
    % initialization
    lik = 0; 
    data.rt = max(eps,data.rt - T);

    % state/action mapping to value
    Q = zeros(4,2);
    % state mapping to value
    V = zeros(4,1);
    mx = max(data.rt)+0.1;  % max RT
    states = data.trial_type;
    
    for t = 1:data.N
        
        % data for current trial
        c = data.c(t)+1;            % choice: 1 for no go, 2 for go
        r = data.r(t);              % reward: 0,1,-1
        s = states(t);              % trial type: 1 for go to win, 2 for go to avoid losing
                                    % 3 for no go to win, 4 for no go to avoid losing
  
        
        % calculate pavlovian influence
        if s == 1 || s == 3
            pav = w1*V(s);
        % adjust starting point for avoid losing condition
        elseif s == 2 || s == 4
            pav = w2*V(s);
        end
                                    
        % drift rate
        v = b1 + b2*(Q(s,2)-Q(s,1))+pav;
        
        % accumulate log-likelihod
        % if fitting data
        if ~isnan(data.rt)
            % Go response
            if c == 2 
                % Wiener first passage time distribution calculates pdf that
                % the diffusion process hits the lower boundary at data.rt(t). 
                % We pass in negative drift rate so lower boundary becomes "go"
                P = wfpt(data.rt(t),-v,a);  
            % NoGo response
            else
                % Given we don't have reaction times for nogo, we calculate the
                % cumulative probability of hitting the nogo boundary during
                % the time of the trial (o to mx)
                P = integral(@(y) wfpt(y,v,a),0,mx);
            end
        else
            % simulating data
            % get probability of hitting go boundary during entire trial
            % (1.5 seconds)
            P = integral(@(y) wfpt(y,-v,a),0,1.5);
            
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
            fprintf("Negative probability calculated!");
        end


        if isnan(P) || P==0; P = realmin; end % avoid NaNs and zeros in the logarithm
        lik = lik + log(P);
        
        % update values
        % if win trial
        if s == 1 || s == 3
            Q(s,c) = Q(s,c) + alpha_win*(r - Q(s,c));
            V(s) = V(s) + alpha_win*(r-V(s));
        % if loss trial
        elseif s == 2 || s == 4
            Q(s,c) = Q(s,c) + alpha_loss*(r - Q(s,c));
            V(s) = V(s) + alpha_loss*(r-V(s));
        end

         
        
        % store latent variables
        if nargout > 1
            latents.v(t,1) = v;
            %latents.P(t,1) = 1/(1+exp(-a*v));
            %latents.RT_mean(t,1) = (0.5*a/v)*tanh(0.5*a*v)+T;
            latents.P(t,1) = P;
        end
        
    end
    