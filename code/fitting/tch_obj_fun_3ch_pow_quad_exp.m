function obj_fun = tch_obj_fun_3ch_pow_quad_exp(roi, model)
% Generates anonymous objective function that can be passed to fmincon for
% the 3ch-pow-quad-exp model (3-channel model with CTS-pow on sustained,
% quadratic transient, and exponential delay channels).
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
% AS 10/2017

if ~strcmp(model.type, '3ch-pow-quad-exp'); error('Incompatible model type'); end
stim = model.stim; nruns = size(stim, 1); irfs = model.irfs; fs = model.fs;
run_avgs = roi.run_avgs; baseline = roi.baseline; tr = roi.tr;

delay_fun = @(z) exp(-(1:12000) / (z * 1000));
conv_snS = @(x, y) cellfun(@(X, Y) convolve_vecs(X, irfs.nrfS{1}, 1, 1) .^ Y, ...
    x, repmat({y}, nruns, 1), 'uni', false);
conv_snT = @(x) cellfun(@(X) convolve_vecs(X, irfs.nrfT{1}, 1, 1) .^ 2, ...
    x, 'uni', false);
doffsets = cellfun(@(X, Y) [X(2:end) Y], model.onsets, model.run_durs, 'uni', false);
conv_snD = @(x, z) cellfun(@(X, Z, ON, OFF) code_exp_decay(X, ON, OFF, Z, fs), ...
    cellfun(@code_delay_act, x, 'uni', false), repmat({delay_fun(z)}, nruns, 1), ...
    model.offsets, doffsets, 'uni', false);
conv_nbS = @(x, y) cellfun(@(NS) convolve_vecs(NS, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snS(x, y), 'uni', false);
conv_nbT = @(x) cellfun(@(NT) convolve_vecs(NT, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snT(x), 'uni', false);
conv_nbD = @(x, z) cellfun(@(ND) convolve_vecs(ND, irfs.hrf{1}, fs, 1 / tr), ...
    conv_snD(x, z), 'uni', false);
conv_nb = @(x, y, z) cellfun(@(S, T, D) [S T D], ...
    conv_nbS(x, y), conv_nbT(x), conv_nbD(x, z), 'uni', false);
comp_bs = @(m, b0) cellfun(@(M, B0) M - repmat(B0, size(M, 1), 1), ...
    m, b0, 'uni', false);
comp_ws = @(x, y, z, m, b0) cell2mat(conv_nb(x, y, z)) \ cell2mat(comp_bs(m, b0));
pred_bs = @(x, y, z, m, b0) cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
    conv_nb(x, y, z), repmat({comp_ws(x, y, z, m, b0)'}, nruns, 1), 'uni', false);
calc_br = @(x, y, z, m, b0) cellfun(@(S, M) (sum(S, 2) - M) .^ 2, ...
    pred_bs(x, y, z, m, b0), comp_bs(m, b0), 'uni', false);
calc_me = @(x, y, z, m, b0) sum(cell2mat(calc_br(x, y, z, m, b0)));
obj_fun = @(x) calc_me(stim, x(1), x(2), run_avgs, baseline);

end