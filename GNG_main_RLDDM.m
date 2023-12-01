% MAIN GO NO GO WRAPPER
rng(23);
dbstop if error

SIM = TRUE;
FIT = FALSE;

% load the data in
if ispc
    root = 'L:';
    fileName = 'L:/rsmith/lab-members/cgoldman/go_no_go/DDM/processed_behavioral_files_DDM/AA022_processed_behavioral_file.csv';
    results_dir = 'L:/rsmith/lab-members/cgoldman/go_no_go/DDM/RL_DDM_Millner/RL_DDM_fits';
    lastSlashPos = find(fileName == '/', 1, 'last');
    subject = fileName(lastSlashPos + 1 : lastSlashPos + 5);
else
    root = '/media/labs';
    fileName = getenv('SUBJECT');
    results_dir = getenv('RESULTS');
    lastSlashPos = find(fileName == '/', 1, 'last');
    subject = fileName(lastSlashPos + 1 : lastSlashPos + 5);
end

if SIM
    gen_params.b1 = fit_result.x(1);
    gen_params.b2 = fit_result.x(2);
    gen_params.w1 = fit_result.x(3);
    gen_params.w2 = fit_result.x(4);
    gen_params.a = fit_result.x(5);
    gen_params.alpha_win = fit_result.x(6);
    gen_params.alpha_loss = fit_result.x(7);
    gen_params.T = fit_result.x(8);
    disp(['Simulating game from AA022']);
    outcomes, gen_choices = sim_gonogo(gen_params);
    
end

if FIT
    addpath([root '/rsmith/lab-members/cgoldman/go_no_go/DDM/RL_DDM_Millner/mfit-master']);
    data = load_gonogo_data(fileName);
    disp(['Fitting subject ', subject]);
    % fit the data
    fit_result = fit_gonogo_fmincon(data);

    % create res object
    res.subject = subject;
    res.b1 = fit_result.x(1);
    res.b2 = fit_result.x(2);
    res.w1 = fit_result.x(3);
    res.w2 = fit_result.x(4);
    res.a = fit_result.x(5);
    res.alpha_win = fit_result.x(6);
    res.alpha_loss = fit_result.x(7);
    res.T = fit_result.x(8);
    res.log_lik = fit_result.loglik;
    res.bic = fit_result.bic;
    res.aic = fit_result.aic;

    writetable(struct2table(res), [results_dir '/GNG_RLDDM-' subject '_fits.csv']);
    save([results_dir '/' subject '_fit_result'], 'fit_result');
end


