%TABLE_3X3 任务2.1 三乘三验证表：飞机模式 × 风况, 单元格=MOE(纯能耗 Emin/Eactual)。
% 飞机模式: 悬停(v=0) / 匀速转圈(地速≡u*) / 变速转圈(windinfer 动态决策)。
% 风况: 无风 / 恒定风(3.5 m/s @40°) / 变风(composite: 慢变正弦+湍流)。
% 口径: 每格3种子(3/6/9)均值, duration=600 s(约6整圈); known oracle 作参考上限。
% 结果打印并写入 docs/table_3x3.md(每轮固定验证交付物, 见 ROADMAP.md)。
root=fileparts(mfilename('fullpath')); addpath(root);
outDir=fullfile(root,'docs'); if ~exist(outDir,'dir'), mkdir(outDir); end
modeNames={'悬停(v=0)';'匀速转圈@u*';'变速转圈(windinfer)'};
windNames={'无风';'恒定风';'变风'};
windCfg={...
 {'windKind','const','windBias',0.0,'windBiasY',0.0,'windAmp',0.0,'windAmpY',0.0};...
 {'windKind','const','windBias',3.5,'windBiasY',0.0,'windAmp',0.0,'windAmpY',0.0,'windDirDeg',40};...
 {'windKind','composite','windBias',2.5,'windAmp',1.5,'windOmega',0.08,...
  'windBiasY',0.0,'windAmpY',0.0,'turbStd',0.3}};
M=nan(3,3); K=zeros(1,3);
for iw=1:3
    for im=1:3
        vals=[];
        for sd=[3 6 9]
            c=w21.config('seed',sd,'duration',600,'tailSteps',60,windCfg{iw}{:});
            scn=w21.scenario('static',c);
            if im==3
                [log,~]=w21.run_algorithm('windinfer',scn,c);
            else
                if im==1, olv=0; else, olv=c.optimum0; end
                c2=w21.config(c,'openLoopV',olv);
                [log,~]=w21.run_algorithm('openloop',scn,c2);
                c=c2;
            end
            vals(end+1)=w21.mop_moe(log,c).MOE_energy; %#ok<AGROW>
        end
        M(im,iw)=mean(vals);
        fprintf('%s × %s : MOE=%.4f (3种子均值)\n',modeNames{im},windNames{iw},M(im,iw));
    end
    for sd=[3 6 9]
        c=w21.config('seed',sd,'duration',600,'tailSteps',60,windCfg{iw}{:});
        [log,~]=w21.run_algorithm('known',w21.scenario('static',c),c);
        K(iw)=K(iw)+w21.mop_moe(log,c).MOE_energy/3;
    end
end
fid=fopen(fullfile(outDir,'table_3x3.md'),'w','n','UTF-8');
cl=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,['# 任务2.1 三乘三验证表\n\n生成时间：%s | MOE=纯能耗口径 Emin/Eactual'...
    '(2026-09-04用户口径) | 每格3种子均值, 600 s(约6整圈) | 对象: 空速=地速−风, '...
    'u*固定已知, 风未知\n\n'],datestr(now,31));
fprintf(fid,'| 飞机模式 \\ 风况 | 无风 | 恒定风(3.5@40°) | 变风(composite) |\n|---|---:|---:|---:|\n');
for im=1:3
    fprintf(fid,'| %s | %.4f | %.4f | %.4f |\n',modeNames{im},M(im,1),M(im,2),M(im,3));
end
fprintf(fid,'\n参考上限(known oracle, 非因果): | %.4f | %.4f | %.4f |\n',K(1),K(2),K(3));
fprintf(fid,['\n判读: 匀速转圈以u*为地速, 空速沿圆周波动(顺风/逆风交替), 恒定风下损失'...
    '最大(0.94); windinfer 由功率调制反推风矢量并闭式补偿, 无风/恒定风逼近known上限'...
    '且全程无探针能耗, 变风受估计滞后约束仍优于匀速开环。悬停行: 悬停功率=J0(|w|), '...
    '本标定曲线自悬停向u*单调下降, 故有风时悬停能耗反而略降(曲线形状所致); '...
    '若采用真实U型悬停功率曲线(悬停功率显著高于巡航), 悬停行将显著更差。\n']);
fprintf('表已写入 docs/table_3x3.md\n');
disp(M);
fprintf('TABLE DONE\n');
