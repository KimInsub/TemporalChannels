clear
cd /localhome/insubkim/Documents/experiments/TemporalChannels

addpath(genpath('/localhome/insubkim/Documents/experiments/TemporalChannels'));


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

% preprocess and store run timeseries of each voxel
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
% [roi(1), model(1)] = tch_fit(roi(1), model(1));

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
%%

figure();
nsub=3;
counter=1;
for subj = 1:nsub

for ee= 1:3
    subplot(nsub,3,counter)


estimated_Beta=roi.model.betas{subj};
estimated_Beta=round(estimated_Beta,2);
varExp=round(roi.model.varexp{subj},2);

D=cell2mat(roi.trials(:,subj,ee));
S=cell2mat(model.trial_preds.S(:,subj,ee));
T=cell2mat(model.trial_preds.T(:,subj,ee));
S_B=cell2mat(roi.trial_predsS(:,subj,ee));
T_B=cell2mat(roi.trial_predsT(:,subj,ee));
ST_B=cell2mat(roi.trial_preds(:,subj,ee));

plot(D); hold on
plot(mean(D,2),'g','LineWidth',2);hold on 

plot(S,'b--','LineWidth',2); hold on 
plot(T,'r--','LineWidth',2); hold on 
plot(S+T,'k--','LineWidth',2); hold on 

plot(S_B,'b','LineWidth',2); hold on 
plot(T_B,'r','LineWidth',2); hold on 
plot(ST_B,'k','LineWidth',2)


title(['VarExp: ' num2str(varExp) ' Betas S: ' num2str(estimated_Beta(1)) ', ' 'T: ' num2str(estimated_Beta(2))])
ylim([-2 5])

counter=counter+1;
end

end

%% summary

summary=[];
for ss=1:length(roi.session_ids)
summary(ss).varExp=cell2mat(roi.model.varexp(ss));
summary(ss).Beta=cell2mat(roi.model.betas(ss)');

end


%%
cv_flag=1;

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
        
        % Seems unneccesary to run the code below, but this is a procedure to obtain
        % rBetas
        [roi(vn), model(vn)] = tch_fit(roi(vn), model(vn), opt_proc, fit_exps);
        roi(vn) = tch_pred(roi(vn), model(vn));
        
        %store for messing-around
        troi=roi;
        tmodel=model;
        
        % use model fit from fit_exps to predict data in val_exps
        % concat all test-runs and use the beta-values from estimation,
        % derive beta-weighted pred_runs and calculate R-sqaure. 
        roi(vn) = tch_recompute(roi(vn), model(vn), roi(1).model);
    end
end


%%
summary=[];
for i = 1:length(roi)
% each subject/ Session's Varience explained
summary(i).name=roi(1).name;
summary(i).experiments=roi(i).experiments;

summary(i).sessions=roi(i).session_ids;
summary(i).model=roi(i).model.type;

summary(i).varExp=cell2mat(roi(i).model.varexp);

% below line is to see how across correlation works
% summary.varExp=reshape(summary.varExp,[2,length(summary.varExp)/2])';

% beta values of sustained and transient one column = sustained and next column = transient
summary(i).beta=cell2mat(roi(i).model.betas'); 

% check correlation within same individuals across two sessions
% a=corr(summary.varExp(:,1),summary.varExp(:,2)); 
end

%% insepection

figure()
plot(summary(1).varExp); hold on; plot(summary(2).varExp);
[corVal, pVal ]=corr(summary(1).varExp',summary(2).varExp');
title(['train & test varExp across sessions, r=' num2str(round(corVal,2))])

figure()
bar([mean(summary(1).varExp),mean(summary(2).varExp)]);

