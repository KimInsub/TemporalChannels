function obj_fun = tch_obj_fun_2ch_exp_cquad_opt(roi, model)
% Generates anonymous objective function that can be passed to fmincon for
% the 2ch-exp-quad-opt model (optimized 2-channel model with adapted 
% sustained and compressed quadratic transient channels).
% 
% INPUTS:
%   1) roi: tchROI object containing single session
%   2) model: tchModel object for the same session
% 
% OUTPUTS:
%   obj_fun: anonymous objective function in the form of y = f(x0), where
%   x0 is a vector of parameters to evaluate and y is the sum of squared
%   residual error between model predictions and run response time series
% 
% AS 1/2018

if ~strcmp(model.type, '2ch-exp-cquad-opt'); error('Incompatible model type'); end
stim = model.stim; nruns = size(stim, 1); irfs = model.irfs; fs = model.fs;
run_avgs = roi.run_avgs; baseline = roi.baseline; tr = roi.tr;
% generate IRFs/filters for optimization
nrfS_fun = @(tau) tch_irfs('S', tau);
nrfT_fun = @(tau) tch_irfs('T', tau);
adapt_fun = @(tau_ae) exp(-(1:60000) / (tau_ae * 1000));
div_lpf = @(f) exp(-(0:1999) / f) / sum(exp(-(0:999) / f));
% sustained response: (stimulus * sustained IRF) x exponential[tau_ae]
conv_snS = @(s, tau, tau_ae) cellfun(@(X, Y, ON, OFF) code_exp_decay(X, ON, OFF, Y, fs), ...
    cellfun(@(XX, YY) convolve_vecs(XX, YY, 1, 1), s, repmat({nrfS_fun(tau)}, nruns, 1), 'uni', false), ...
    repmat({adapt_fun(tau_ae)}, nruns, 1), model.onsets, model.offsets, 'uni', false);

% transient linear response: stim * transient IRF[tau_s]
conv_snT = @(s, tau) cellfun(@(X, Y) convolve_vecs(X, Y, 1, 1), ...
    s, repmat({nrfT_fun(tau)}, nruns, 1), 'uni', false);
% transient filtered response: (linear response * low-pass filter[tau2])^2
conv_fnT = @(s, tau, f) cellfun(@(X, F) convolve_vecs(X, F, fs, fs) .^ 2, ...
    conv_snT(s, tau), repmat({div_lpf(f)}, nruns, 1), 'uni', false);
% transient compressed response: (linear response)^2 / (sigma^2 + filtered response)
comp_cnT = @(s, tau, z, f) cellfun(@(N, F, Z) (N .^ 2) ./ (F + Z .^ 2), ...
    conv_snT(s, tau), conv_fnT(s, tau, f), repmat({z}, nruns, 1), 'uni', false);

% sustained BOLD: sustained response * HRF
conv_nbS = @(s, tau, tau_ae) cellfun(@(NS) convolve_vecs(NS, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snS(s, tau, tau_ae), 'uni', false);
% transient BOLD: transient response * HRF
conv_nbT = @(s, tau, z, f) cellfun(@(NT) convolve_vecs(NT, irfs.hrf{1}, fs, 1 / tr), ...
    comp_cnT(s, tau, z, f), 'uni', false);
% channel predictors: [sustained BOLD, transient BOLD, persistent BOLD]
conv_nb = @(s, tau, tau_ae, z, f) cellfun(@(S, T) [S T], ...
    conv_nbS(s, tau, tau_ae), conv_nbT(s, tau, z, f), 'uni', false);
% measured signal: time series - baseline estimates
comp_bs = @(m, b0) cellfun(@(M, B0) M - repmat(B0, size(M, 1), 1), ...
    m, b0, 'uni', false);
% channel weights: channel predictors \ measured signal
comp_ws = @(s, tau, tau_ae, z, f, m, b0) cell2mat(conv_nb(s, tau, tau_ae, z, f)) \ cell2mat(comp_bs(m, b0));
% predicted signal: channel predictors x channel weights
pred_bs = @(s, tau, tau_ae, z, f, m, b0) cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
    conv_nb(s, tau, tau_ae, z, f), repmat({comp_ws(s, tau, tau_ae, z, f, m, b0)'}, nruns, 1), 'uni', false);
% model residuals: (predicted signal - measured signal)^2
calc_br = @(s, tau, tau_ae, z, f, m, b0) cellfun(@(S, M) (sum(S, 2) - M) .^ 2, ...
    pred_bs(s, tau, tau_ae, z, f, m, b0), comp_bs(m, b0), 'uni', false);
% model error: summed squared residuals for all run time series
calc_me = @(s, tau, tau_ae, z, f, m, b0) sum(cell2mat(calc_br(s, tau, tau_ae, z, f, m, b0)));
obj_fun = @(x) calc_me(stim, x(1), x(2), x(3), x(4), run_avgs, baseline);

end