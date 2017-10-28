function model = pred_runs_2ch_div_quad(model)
% Generates run predictors using the 2 temporal-channel model with CTS-div
% on sustained and quadratic transient channel. 

% get design parameters
fs = model.fs; tr = model.tr; stim = model.stim;
nruns_max = size(stim, 1); empty_cells = cellfun(@isempty, stim);
params_names = fieldnames(model.params); params = [];
for pp = 1:length(params_names)
    pname = model.params.(params_names{pp});
    params.(params_names{pp}) = repmat(pname, nruns_max, 1);
end
irfs_names = fieldnames(model.irfs); irfs = [];
for ff = 1:length(irfs_names)
    iname = model.irfs.(irfs_names{ff});
    irfs.(irfs_names{ff}) = repmat(iname, nruns_max, 1);
end

% generate run predictors for each session
predSn = cellfun(@(X, Y) convolve_vecs(X, Y, fs, fs) .^ 2, ...
    stim, irfs.nrfS, 'uni', false);
predSd = cellfun(@(X, Y) X + Y .^ 2, predSn, params.sigma, 'uni', false);
predS = cellfun(@(X, Y) X ./ Y, ...
    predSn, predSd, 'uni', false); predS(empty_cells) = {[]};
predTr = cellfun(@(X, Y) convolve_vecs(X, Y, fs, fs) .^ 2, ...
    stim, irfs.nrfT, 'uni', false); predTr(empty_cells) = {[]};
fmriS = cellfun(@(X, Y) convolve_vecs(X, Y, fs, 1 / tr), ...
    predS, irfs.hrf, 'uni', false); fmriS(empty_cells) = {[]};
fmriT = cellfun(@(X, Y) convolve_vecs(X, Y, fs, 1 / tr), ...
    predTr, irfs.hrf, 'uni', false); fmriT(empty_cells) = {[]};
run_preds = cellfun(@(X, Y) [X Y * model.normT], fmriS, fmriT, 'uni', false);
model.run_preds = run_preds;

end