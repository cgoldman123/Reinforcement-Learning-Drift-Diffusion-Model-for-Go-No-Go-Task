function extractparams()
directory = dir('L:\rsmith\lab-members\cgoldman\go_no_go\DDM\RL_DDM_Millner\RL_DDM_fits\fixed_model_accuracy');
index_array = find(arrayfun(@(n) contains(directory(n).name, 'csv'),1:numel(directory)));
for index = index_array
    file = [directory(index).folder '\' directory(index).name];
    opts = detectImportOptions(file, 'TextType', 'string');
    subdat{index} = readtable(file, opts);
end
% Identify valid entries in subdat
valid_indices = find(cellfun(@(x) ~isempty(x), subdat));

nValidEntries = numel(valid_indices);
first_valid_table = subdat{valid_indices(1)};
nVars = width(first_valid_table);

% Extract column names
colnames = first_valid_table.Properties.VariableNames;

% Initialize matrices
fitted_data = cell(nValidEntries, nVars);


for i = 1:nValidEntries
    idx = valid_indices(i);
    for j = 1:nVars
        try
            fitted_data{i, j} = num2str(subdat{idx}.(colnames{j}));
        catch e
            e
        end
    end
end


fit_table = cell2table(fitted_data, 'VariableNames', colnames);

writetable(fit_table, ['L:\rsmith\lab-members\cgoldman\go_no_go\r_stats\' 'GNG_RLDDM_fixed_model_accuracy.csv'], 'WriteRowNames',true);




