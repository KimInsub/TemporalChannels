[mdir, ~] = fileparts(pwd); addpath(genpath(mdir));
model_type = '2ch-exp-sig';
rois = {'mFus_faces' 'OTS_bodies' 'mOTS_characters' ...
        'pSTS_faces' 'MTG_bodies' 'V1' 'hV4' 'MT' ...
        'pFus_faces' 'ITG_bodies' 'pOTS_characters' ...
        'IOG_faces' 'LOS_bodies' 'IOS_characters' 'V2' 'V3'};
fit_exps = {'ExpAo' 'ExpBo' 'ExpCo'; 'ExpAe' 'ExpBe' 'ExpCe'};
val_exps = {'ExpAe' 'ExpBe' 'ExpCe'; 'ExpAo' 'ExpBo' 'ExpCo'};
sessions = {'as' 'bj' 'cs' 'em' 'jg' 'kg' 'md' 'mg' 'sc' 'wd' 'yl'};
sessions_sub = {'as' 'bj' 'cs' 'jg' 'kg' 'mg' 'sc'};

for rr = 1:length(rois)
    fname = [strrep(rois{rr}, '_', '-') '_' model_type '_split-half.mat'];
    if exist(fullfile(mdir, 'results', fname), 'file') == 0
        [roi1, model1] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(1, :), val_exps(1, :), 1, sessions);
        [roi2, model2] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(2, :), val_exps(2, :), 1, sessions);
        roi = pool_across_folds(roi1, roi2);
        save(fullfile(mdir, 'results', fname), 'roi');
    end
    fname = [strrep(rois{rr}, '_', '-') '_' model_type '_split-half2.mat'];
    if exist(fullfile(mdir, 'results', fname), 'file') == 0
        [roi1, model1] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(1, :), val_exps(1, :)', 1, sessions);
        [roi2, model2] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(2, :), val_exps(2, :)', 1, sessions);
        roi = pool_across_folds(roi1, roi2);
        save(fullfile(mdir, 'results', fname), 'roi');
    end
    fname = [strrep(rois{rr}, '_', '-') '_' model_type '_split-half-sub.mat'];
    if exist(fullfile(mdir, 'results', fname), 'file') == 0
        [roi1, model1] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(1, :), val_exps(1, :), 1, sessions_sub);
        [roi2, model2] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(2, :), val_exps(2, :), 1, sessions_sub);
        roi = pool_across_folds(roi1, roi2);
        save(fullfile(mdir, 'results', fname), 'roi');
    end
    fname = [strrep(rois{rr}, '_', '-') '_' model_type '_split-half-exps.mat'];
    if exist(fullfile(mdir, 'results', fname), 'file') == 0
        [roi1AB, model1AB] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(1, :), val_exps(1, 1:2), 1, sessions, 0);
        [roi2AB, model2AB] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(2, :), val_exps(2, 1:2), 1, sessions, 0);
        roiAB = pool_across_folds(roi1AB(2), roi2AB(2));
        [roi1C, model1C] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(1, :), val_exps(1, 3), 1, sessions, 0);
        [roi2C, model2C] = tch_model_roi(rois{rr}, model_type, ...
            fit_exps(2, :), val_exps(2, 3), 1, sessions, 0);
        roiC = pool_across_folds(roi1C(2), roi2C(2));
        save(fullfile(mdir, 'results', fname), 'roiAB', 'roiC');
    end
end
