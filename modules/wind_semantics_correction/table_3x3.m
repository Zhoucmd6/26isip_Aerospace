%TABLE_3X3 任务1.11 三乘三验证表: 飞机模式 × 风况, 单元格=MOE(纯能耗 Emin/Eactual)。
% MOE = sum(minPowerTrue)/sum(powerTrue), 与 mop_moe 的 MOE_energy 完全同式
% (2026-09-04用户口径: MOE只考虑续航能耗)。每格3种子(3/6/9)均值, duration=600s。
% 悬停/匀速行直接驱动黑箱对象(定速, 无反馈); 变速行用本任务最优因果算法 qnewton。
% 本表为每轮固定验证交付物(见 ../ROADMAP.md)。结果写入 docs/table_3x3.md。
root=fileparts(mfilename('fullpath')); addpath(root);
outDir=fullfile(root,'docs'); if ~exist(outDir,'dir'), mkdir(outDir); end
modeNames={'悬停(v=0)';'匀速转圈@u*';'变速转圈(qnewton)'};
windNames={'无风';'恒定风';'变风'};
M=nan(3,3); K=zeros(1,3); KOK=false;
for iw=1:3
    for im=1:3
        vals=[];
        for sd=[3 6 9]
            if iw==1
                c=w10.config('seed',sd,'duration',600,'tailSteps',60,'windKind','const','windAmp',0,'windBias',0,'windAmpY',0,'windBiasY',0);
            elseif iw==2
                c=w10.config('seed',sd,'duration',600,'tailSteps',60,'windKind','const','windBias',3.5,'windBiasY',0,'windAmp',0,'windAmpY',0,'windDirDeg',40);
            elseif iw==3
                c=w10.config('seed',sd,'duration',600,'tailSteps',60,'windKind','composite','windBias',2.5,'windAmp',1.5,'windOmega',0.08,'windBiasY',0,'windAmpY',0,'turbStd',0.3);
            end
            scn=w10.scenario('static',c);
            plant=w10.make_plant(scn,c);
            modeV=[0, c.optimum0, NaN];   % 悬停 / 匀速(=u*) / 算法行
            if im==3
                [log,~]=w10.run_algorithm('qnewton',scn,c);
            else
                v0=modeV(im);
                while plant.count()<c.duration
                    plant.q(v0,'hold'); plant.amendEstimate(v0);
                end
                log=plant.table();
            end
            vals(end+1)=sum(log.minPowerTrue)/sum(log.powerTrue); %#ok<AGROW>
        end
        M(im,iw)=mean(vals);
        fprintf('%s × %s : MOE=%.4f\n',modeNames{im},windNames{iw},M(im,iw));
    end
    for sd=[3 6 9]
            if iw==1
                c=w10.config('seed',sd,'duration',600,'tailSteps',60,'windKind','const','windAmp',0,'windBias',0,'windAmpY',0,'windBiasY',0);
            elseif iw==2
                c=w10.config('seed',sd,'duration',600,'tailSteps',60,'windKind','const','windBias',3.5,'windBiasY',0,'windAmp',0,'windAmpY',0,'windDirDeg',40);
            elseif iw==3
                c=w10.config('seed',sd,'duration',600,'tailSteps',60,'windKind','composite','windBias',2.5,'windAmp',1.5,'windOmega',0.08,'windBiasY',0,'windAmpY',0,'turbStd',0.3);
            end
        [logK,~]=w10.run_algorithm('known',w10.scenario('static',c),c);
        K(iw)=K(iw)+sum(logK.minPowerTrue)/sum(logK.powerTrue)/3; KOK=true;
    end
end
fid=fopen(fullfile(outDir,'table_3x3.md'),'w','n','UTF-8');
cl=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,['# 任务1.11 三乘三验证表\n\n生成时间：%s | MOE=纯能耗口径 Emin/Eactual '...
    '(2026-09-04用户口径) | 每格3种子均值 | duration=600 s\n\n'],datestr(now,31));
fprintf(fid,'| 飞机模式 \\ 风况 | 无风 | 恒定风 | 变风 |\n|---|---:|---:|---:|\n');
for im=1:3
    fprintf(fid,'| %s | %.4f | %.4f | %.4f |\n',modeNames{im},M(im,1),M(im,2),M(im,3));
end
if KOK
    fprintf(fid,'\n参考上限(known oracle, 非因果): | %.4f | %.4f | %.4f |\n',K(1),K(2),K(3));
end
fprintf(fid,'\n风况说明: 恒定风=const 3.5 m/s; 变风=composite(慢变正弦+OU湍流σ=0.3, 最贴近实际)。对象含物理转弯半径/通信时延/加速度限幅与七种风场模型库。MOE为纯能耗口径(2026-09-04); known为评价侧oracle参照(非因果)。全部结论为虚拟/代理对象(AGENTS.md红线3)。\n');
fprintf('表已写入 docs/table_3x3.md\n');
disp(M);
fprintf('TABLE DONE\n');
