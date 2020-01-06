subplot(2,2,1)
plot(stim{1}(10000:30000)) ; hold on
plot(predS{1}(10000:30000)); hold on

ylim([0 2])
xlim([0 15000])


subplot(2,2,2)
plot(stim{1}(10000:30000)) ; hold on
plot(predTq{1}(10000:30000)); hold on

ylim([0 2])
xlim([0 15000])


subplot(2,2,3)
% plot(stim{1}(10000:30000)) ; hold on
% plot(predS{1}(10000:30000)); hold on
plot(fmriS{1}(10:30)); hold on

ylim([0 2])
% xlim([0 15])



subplot(2,2,4)
% plot(stim{1}(10000:30000)) ; hold on
% plot(predTq{1}(10000:30000)); hold on
plot(fmriT{1}(10:30)); hold on

ylim([0 .01])
% xlim([0 15])

plot(fmriT{1}(10:30)+fmriS{1}(10:30)); hold on
ylim([0 2])


%model.trial_preds(nconds_max, nsess, nexps);
exp=1:3;
exp=1
model.trial_preds.S(:,1,exp)
figure()
for conds = 1:5
   subplot(1,5,conds) 
   plot(model.trial_preds.S{conds,1,exp})
    ylim([0 1.5])
    xlim([0 50])

end

figure()
for conds = 1:5
   subplot(1,5,conds) 
   plot(model.trial_preds.T{conds,1,exp})
    ylim([0 1.5])
    xlim([0 50])

end

figure()
plot(tc(1:276)); hold on
plot(roi.model.run_preds{1}(1:276)); hold on
plot(mm.residual(1:276)); hold on

%%
figure()
t1 =predictors(:,1) *mm.betas(1)
t2 =predictors(:,2) *mm.betas(2)
plot(tc(1:276)); hold on
plot(t1(1:276)); hold on
plot(t2(1:276)); hold on

figure()
plot(tc(1104:1380)); hold on
plot(t1(1104:1380)); hold on
plot(t2(1104:1380)); hold on


%%
for exp =1:3
    figure()

for conds = 1:5
    subplot(1,5,conds) 
plot(roi.trial_avgs{conds,1,exp}); hold on;
   plot(model.trial_preds.S{conds,1,exp})
   plot(model.trial_preds.T{conds,1,exp})
   plot(model.trial_preds.S{conds,1,exp}+model.trial_preds.T{conds,1,exp})
  

     ylim([-1 5])
    xlim([0 50])


end


name = ['exp' num2str(exp) '.png'];
saveas(gcf,name)

end
