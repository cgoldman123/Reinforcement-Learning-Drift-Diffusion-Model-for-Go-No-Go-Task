% MAIN GO NO GO WRAPPER
clear all;
rng(23);
dbstop if error

SIM = false;
FIT = true;
use_fmincon = false;
use_laplace = true;
plot = true;
use_ddm = true;

% load the data in
if ispc
    root = 'L:';
    fileName = 'L:/rsmith/lab-members/cgoldman/go_no_go/DDM/processed_behavioral_files_DDM/BE387_processed_behavioral_file.csv';
    results_dir = 'L:/rsmith/lab-members/cgoldman/go_no_go/DDM/RL_DDM_Millner/RL_DDM_fits';
    lastSlashPos = find(fileName == '/', 1, 'last');
    subject = fileName(lastSlashPos + 1 : lastSlashPos + 5);
else
    root = '/media/labs';
    fileName = getenv('SUBJECT');
    results_dir = getenv('RESULTS');
    estimation_prior = getenv('ESTIMATION_PRIOR');
    field = getenv('FIELD');
    lastSlashPos = find(fileName == '/', 1, 'last');
    subject = fileName(lastSlashPos + 1 : lastSlashPos + 5);
    DCM.MDP = estimation_prior;
    DCM.field = field;
end

if SIM
    gen_params.rs = 1;
    gen_params.la = 1;
    gen_params.alpha_win = .5;
    gen_params.alpha_loss = .5;
    gen_params.beta = .5;
    gen_params.zeta = .5;
    gen_params.pi_win = .5;
    gen_params.pi_loss = 2;
    gen_params.T = .25;
    gen_params.a = 2;
    disp(['Simulating game from AA022']);
    model_output = sim_gonogo(gen_params,use_ddm);
    
end

if FIT
    estimation_prior.rs = 1;
    estimation_prior.la = 1;
    estimation_prior.alpha_win = .5;
    estimation_prior.alpha_loss = .5;
    estimation_prior.beta = .5;
    estimation_prior.zeta = .5;
    estimation_prior.pi_win = .5;
    estimation_prior.pi_loss = .5;
    estimation_prior.T = .25;
    estimation_prior.a = 2;
    DCM.MDP = estimation_prior;
    DCM.field = {'alpha_win'; 'alpha_loss'; 'beta'; 'zeta'; 'pi_win'; 'pi_loss';'a'};
    data = load_gonogo_data(fileName);
    if use_fmincon
        addpath([root '/rsmith/lab-members/cgoldman/go_no_go/DDM/RL_DDM_Millner/mfit-master']);
        disp(['Fitting subject with fmincon:', subject]);
        fit_result = fit_gonogo_fmincon(data);
        res.fit_method = "fmincon";
    
    elseif use_laplace
        disp(['Fitting subject with variational laplace:', subject]);
        addpath([root '/rsmith/all-studies/util/spm12/']);
        addpath([root '/rsmith/all-studies/util/spm12/toolbox/DEM/']);
        DCM.use_ddm = use_ddm;
        DCM.U = data;
        DCM.Y = [];
        fit_result = fit_gonogo_laplace(DCM,plot);
        res.fit_method = "laplace";
    end
    
    % create res object
    res.subject = subject;
    res.use_ddm = use_ddm;
    res.avg_action_probability = fit_result.avg_action_probability;
    res.model_accuracy = fit_result.model_accuracy;
    res.F = fit_result.F;

    % Loop over prior and posterior values
    params = fieldnames(fit_result.prior);
    for i = 1:length(params)
        param = params{i};
        res.(strcat(param,"_prior")) = fit_result.prior.(param);
        if isfield(fit_result.posterior, param)
            res.(param) = fit_result.posterior.(param);
        end
    end

   % res.aic = fit_result.aic;

    writetable(struct2table(res), [results_dir '/GNG_RLDDM-' subject '_fits.csv']);
    save([results_dir '/' subject '_fit_result'], 'fit_result');
    saveas(gcf,[results_dir '/' subject '_fit_plot.png']);
    clear all; clf;
end


