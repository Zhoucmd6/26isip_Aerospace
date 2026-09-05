%SMOKE21 任务2.1无头冒烟矩阵: 4风况 × 4策略 + 悬停/匀速基准。
root='D:\王健祺\大学本科文件资料\大二暑\航空器\控制寻优\speed_esc_matlab\2.1_wind_inference';
cd(root); addpath(root); rehash;
algos={'windinfer','est','known','openloop'};
winds={ % name, extra cfg
 'zero',   {'windKind','const','windBias',0.0,'windBiasY',0.0,'windDirDeg',0};
 'const',  {'windKind','const','windBias',3.5,'windBiasY',0.0,'windDirDeg',40};
 'vary',   {'windKind','composite','windBias',2.5,'windAmp',1.5,'windOmega',0.08,...
            'windBiasY',0.0,'windAmpY',0.0,'turbStd',0.3};
 'strong', {'windKind','const','windBias',5.5,'windBiasY',0.0,'windDirDeg',200};
};
fprintf('%-8s%-11s%9s%9s%10s\n','wind','algo','excess%','MOE','windErr');
for iw=1:size(winds,1)
    for ia=1:numel(algos)
        c=w21.config('seed',3,winds{iw,2}{:});
        scn=w21.scenario('static',c);
        [log,info]=w21.run_algorithm(algos{ia},scn,c);
        m=w21.mop_moe(log,c);
        wErr=NaN;
        if strcmp(algos{ia},'windinfer')
            wTrue=[c.windBias*cosd(c.windDirDeg); c.windBias*sind(c.windDirDeg)];
            we=info.windEst; n2=height(log); hh=we(:,round(n2/2):end);
            wErr=mean(hypot(hh(1,:)-wTrue(1),hh(2,:)-wTrue(2)),'omitnan');
        end
        fprintf('%-8s%-11s%9.2f%9.4f%10.2f\n',winds{iw,1},algos{ia},...
            m.energyExcessPercent,m.MOE_energy,wErr);
    end
end
% ---- 悬停 / 匀速转圈 基准(开放环固定速度) ----
for vw=[0, 6.3]
    c=w21.config('seed',3,'windKind','const','windBias',3.5,'windDirDeg',40,...
        'openLoopV',vw);
    scn=w21.scenario('static',c);
    [log,~]=w21.run_algorithm('openloop',scn,c);
    m=w21.mop_moe(log,c);
    fprintf('fixed v=%4.1f excess %0.2f%% MOE %0.4f (airspeed mean %0.2f)\n',...
        vw,m.energyExcessPercent,m.MOE_energy,mean(log.airspeed));
end
% 零风匀速 = 上限核对
c=w21.config('seed',3,'windKind','const','windBias',0,'openLoopV',6.3);
scn=w21.scenario('static',c);
[log,~]=w21.run_algorithm('openloop',scn,c);
m=w21.mop_moe(log,c);
fprintf('fixed v=6.3 nowind excess %0.3f%% MOE %0.4f\n',m.energyExcessPercent,m.MOE_energy);
fprintf('SMOKE DONE\n');
