% Carter Goldman, 2023

% Plots the action probabilities, observations, and responses for the
% gonogo

% expects the following input
    % MDP
        % .observations [1 x N] double 
        % .choices [1 x N] double 
        % .action_probabilities [1 x N] double
        
    % states_block [N x 1] double
        
        
        

function [] = plot_gonogo(MDP, states_block)
clf;

% 
% graphics
%==========================================================================
% % col   = {'.b','.y','.g','.r','.c','.k'};
% col   = {[0, 0.4470, 0.7410], ...       % blue
%          [0.4660, 0.6740, 0.1880], ...  % green
%          [0.9350, 0.1780, 0.2840], ...  % red
%          [0.4940, 0.1840, 0.5560], ...  % purple
%          [0.3010, 0.7450, 0.9330], ...  % cyan
%          [0, 0, 0]};                    % black

% black and white cols for colormap
cols  = [0:1/32:1; 0:1/32:1; 0:1/32:1]';


o = MDP.observations;
u = MDP.choices;

% Initial states and expected policies
%--------------------------------------------------------------------------

choice_prob(:,:,1) = MDP.action_probabilities(states_block == 1);
choice_prob(:,:,2) = MDP.action_probabilities(states_block == 2);
choice_prob(:,:,3) = MDP.action_probabilities(states_block == 3);
choice_prob(:,:,4) = MDP.action_probabilities(states_block == 4);




% Find the trials corresponding to each block
for block = 1:4

    
    subplot(4,1,block)
    imagesc([1 - choice_prob(:,:,block)]); colormap(cols); hold on;
    switch block
        case 1
            title('Go to Win');
        case 2
            title('Go to Avoid Losing');
        case 3
            title('No Go to Win');
        case 4
            title('No Go to Avoid Losing');
    end

    % Modify y-axis ticks and labels
    set(gca, 'YTick', [0.5, 1.5], 'YTickLabel', {'No Go', 'Go'});
    %y_position_for_text = -0.8; % for adding text for trial number
    % Get trials for this block
    
    block_trials = find(states_block == block);
    
    trial_in_block_counter = 1;
    % Loop through the trials and add circles based on action
    for trial = block_trials'
        
        action = u(trial);
        
        if o(trial) == -1
            color = 'r';
        elseif o(trial) == 0
            color = 'k';
        elseif o(trial) == 1
            color = 'g';
        end
        % Plot circle based on action: top if action == 1, bottom if action == 2
        if action == 1
            scatter(trial_in_block_counter, 0.5, 50, 'o', 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', color);
        elseif action == 2
            scatter(trial_in_block_counter, 1.5, 50, 'o', 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', color);
        end
        %text(trial, y_position_for_text, num2str(trial), 'FontSize', 8);
        trial_in_block_counter = trial_in_block_counter+1;
    end
end

