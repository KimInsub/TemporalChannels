clear
cd /Users/insubkim/Documents/experiment/TemporalChannels

addpath(genpath('/Users/insubkim/Documents/experiment/TemporalChannels'));

%Y = round(tSeries,3);

%[roi, model] = tch_model_roi('V1', '2ch-lin-quad', {'Exp1' 'Exp2'});

%% Fit the model to fit_exps

%tch_model_roi(name, type, fit_exps, val_exps, opt_proc, sessions)
name='V1';
type='2ch-lin-quad';
fit_exps={'Exp1','Exp2','Exp3'};
val_exps={'Exp3'};
opt_proc=0;
% sessions={'s01_ss1'}
% roi(1) = tchROI(name, fit_exps, sessions);
roi(1) = tchROI(name, fit_exps);
roi(1) = tch_runs(roi(1));
%
% figure()
% plot_quick_tc(roi.run_avgs,1)
% figure()
% plot_quick_tc(roi.raw_run_avg,1)
% 
%%


% setup tchModel object to apply to tchROI
model(1) = tchModel(type, fit_exps, roi(1).sessions);
% model(1) = norm_model(model(1), 1); 
nch = model(1).num_channels;
fprintf('Coding the stimulus for %s ...\n', strjoin(fit_exps, ', '));
model(1) = code_stim(model(1));
fprintf('Generating predictors for %s model...\n', type)
model(1) = pred_runs(model(1)); model(1) = pred_trials(model(1));

%%
% fit tchModel to tchROI
fprintf('Extracting trial time series...\n');
roi(1) = tch_trials(roi(1), model(1));  % returns roi.trials // cut stimulus into trials

D=cell2mat(roi.trials(:,1,1));
S=cell2mat(model.trial_preds.S(:,1,1));
T=cell2mat(model.trial_preds.T(:,1,1));


plot(D); hold on 
plot(mean(D,2),'k','LineWidth',2)
plot(S,'b--','LineWidth',2)
plot(T,'r--','LineWidth',2)
plot(S+T,'k--','LineWidth',2)

%%


fprintf('Fitting the %s model...\n', model(1).type); % perform GLM and get beta, end beta weighted run-prediction
[roi(1), model(1)] = tch_fit(roi(1), model(1), opt_proc);
[roi(1), model(1)] = tch_fit(roi(1), model(1));

figure();
plot(model.run_preds{1,1},'LineWidth',1); hold on; %
plot(sum(model.run_preds{1},2),'k','LineWidth',1); hold on; %
% roi.model.run_preds{ss} = predictors * mm.betas';
% beta-weighted predction
plot(roi.model.run_preds{1}(1:length(model.run_preds{1})),'c--','LineWidth',2);             


%% cut prediction into trials 
%returns: roi.trial_predsS roi.trial_predsT roi.trial_preds

roi(1) = tch_pred(roi(1), model(1));


% figure for before beta adjustment
% figure();
% plot(D); hold on 
% plot(mean(D,2),'k','LineWidth',2)
% plot(S,'b--','LineWidth',2); hold on 
% plot(T,'r--','LineWidth',2); hold on 
% plot(S+T,'k--','LineWidth',2); hold on 


figure();
for ee= 1:3
    

estimated_Beta=roi.model.betas{1};
D=cell2mat(roi.trials(:,1,ee));
S=cell2mat(model.trial_preds.S(:,1,ee));
T=cell2mat(model.trial_preds.T(:,1,ee));
S_B=cell2mat(roi.trial_predsS(:,1,ee));
T_B=cell2mat(roi.trial_predsT(:,1,ee));
ST_B=cell2mat(roi.trial_preds(:,1,ee));

subplot(3,1,ee)
plot(D); hold on 
plot(mean(D,2),'k','LineWidth',2);hold on 
plot(S_B,'b--','LineWidth',2); hold on 
plot(T_B,'r--','LineWidth',2); hold on 
plot(ST_B,'k--','LineWidth',2)
title(['Betas    S: ' num2str(estimated_Beta(1)) ', ' 'T: ' num2str(estimated_Beta(2))])
ylim([-2 5])

end
%%
if cv_flag
    num_vals = size(val_exps, 1);
    for vv = 1:num_vals
        vn = vv + 1; exps_str = strjoin(val_exps(vv, :), ', ');
        fprintf('Performing validation for %s...\n', exps_str)
        % setup tchROI and tchModel objects for validation
        roi(vn) = tch_runs(tchROI(name, val_exps(vv, :), roi(1).sessions));
        model(vn) = tchModel(type, val_exps(vv, :), roi(vn).sessions);
        if nch > 1; model(vn).normT = model(1).normT; end
        if nch > 2; model(vn).normP = model(1).normP; end
        model(vn).params = roi(1).model.params; model(vn) = code_stim(model(vn));
        model(vn) = pred_runs(model(vn)); model(vn) = pred_trials(model(vn));
        % setup model struct by first fitting model to validation data
        roi(vn) = tch_trials(roi(vn), model(vn));
        [roi(vn), model(vn)] = tch_fit(roi(vn), model(vn), opt_proc, fit_exps);
        roi(vn) = tch_pred(roi(vn), model(vn));
        % use model fit from fit_exps to predict data in val_exps
        roi(vn) = tch_recompute(roi(vn), model(vn), roi(1).model);
    end
end
