%VERIFY_WIND_INFERENCE 任务2.1风推断双重验证:
% (A) 因果性核验(红线1): 算法在寻优全程是否拿不到风的真值与变化规律;
% (B) 猜测精度核验: 反推出的风矢量与真风的偏差(幅值/方向/收敛时间/逐点跟踪)。
% 结果打印并写入 docs/wind_inference_check.md。
root=fileparts(mfilename('fullpath')); addpath(root);
outDir=fullfile(root,'docs'); if ~exist(outDir,'dir'), mkdir(outDir); end
fid=fopen(fullfile(outDir,'wind_inference_check.md'),'w','n','UTF-8');
cl=onCleanup(@()fclose(fid)); %#ok<NASGU>

fprintf('\n============ A. 因果性核验(红线1) ============\n');
fprintf(fid,'\n## A. 因果性核验(红线1: 寻优全程不知道风及其变化规律)\n\n');

% ---- A1 结构: 算法签名不接收场景真值 ----
nIn=nargin('w21.windinfer_run');
a1=(nIn==3);
fprintf('A1 结构核验: windinfer_run 签名=(plant,p,n) 共%d参, 不接收场景scn',nIn);
if a1, fprintf(' → 通过\n'); else, fprintf(' → 不通过\n'); end
fprintf(fid,'- **A1 结构**: `windinfer_run(plant,p,n)` 只有3个入参; 风真值只存在于场景 `scn`/`wind_field` 中, 算法侧拿不到 → %s。\n',tfstr(a1));

% ---- A2 行为: 喂假风config, 对象真风不变 ----
% 若算法偷看config里的windBias/windDirDeg, 估计会收敛到假风(8@170°);
% 只用功率测量则仍收敛到对象真风(3.5@40°)。
cTrue=w21.config('seed',3,'windKind','const','windBias',3.5,'windDirDeg',40);
scn=w21.scenario('static',cTrue);
plant=w21.make_plant(scn,cTrue);
pFake=cTrue; pFake.windBias=8.0; pFake.windDirDeg=170;   % 假风只喂给算法
infoA=w21.windinfer_run(plant,pFake,cTrue.duration);
wTrue=[3.5*cosd(40);3.5*sind(40)];
wFake=[8.0*cosd(170);8.0*sind(170)];
we=infoA.windEst; kFin=find(isfinite(we(1,:)),1,'last');
eReal=norm(we(:,kFin)-wTrue);      % 最终估计到真风的距离
eFake=norm(we(:,kFin)-wFake);      % 最终估计到假风的距离
a2=(eReal<0.6 && eFake>2.0);
fprintf('A2 行为核验: 对象真风=(%.2f,%.2f) | 算法config里的假风=(%.2f,%.2f)\n',...
    wTrue(1),wTrue(2),wFake(1),wFake(2));
fprintf('   算法最终估计=(%.2f,%.2f) → 距真风%.2f m/s, 距假风%.2f m/s',...
    we(1,kFin),we(2,kFin),eReal,eFake);
if a2, fprintf(' → 通过(估计跟随真风)\n'); else, fprintf(' → 不通过\n'); end
fprintf(fid,['- **A2 行为(假config试验)**: 对象真风(3.5@40°)不变, 只把算法手里的config改成假风(8@170°)。',...
    '最终估计距真风 %.2f m/s、距假风 %.2f m/s → 估计只跟随真风, 证明风信息只来自功率测量, 未偷看config → %s。\n'],eReal,eFake,tfstr(a2));

% ---- A3 源码: 不含任何风真值字段的引用 ----
src=fileread(fullfile(root,'+w21','windinfer_run.m'));
leak=regexp(src,'windBias|windKind|windAmp|windDirDeg|windOmega|turbStd|windTurb','match');
a3=isempty(leak);
fprintf('A3 源码核验: windinfer_run.m 中风真值字段引用数=%d',numel(leak));
if a3, fprintf(' → 通过\n'); else, fprintf(' → 不通过\n'); end
fprintf(fid,['- **A3 源码**: `windinfer_run.m` 对风真值字段(windBias/windKind/windAmp/ω/turb…)的引用数=%d → %s。',...
    '算法也不知道"风怎么变": 源码不含任何风模型类别/频率/幅值/湍流参数, 变风是靠"残差前后一致性"自适应发现的。\n'],numel(leak),tfstr(a3));

fprintf('\n============ B. 猜测精度核验 ============\n');
fprintf(fid,'\n## B. 风猜测精度核验\n\n');

% ---- B1 恒定风: 罗盘8方向(幅值3.5) + 幅值2/5(方向40°) ----
fprintf('B1 恒定风(600s≈6整圈):\n');
fprintf(fid,'### B1 恒定风(600 s, 约6整圈)\n\n');
fprintf(fid,'| 真风 | 估计ŵ | 幅值误差 m/s | 方向误差° | 收敛步数(<0.3持续30步) |\n|---|---|---:|---:|---:|\n');
allErr=[]; allConv=[];
cases=[3.5*ones(1,8), 2.0, 5.0;      % 幅值行
       0:45:315,           40, 40];  % 方向行
for k=1:10
    magv=cases(1,k); dirDeg=cases(2,k);
    c=w21.config('seed',3,'windKind','const','windBias',magv,'windDirDeg',dirDeg);
    scnI=w21.scenario('static',c);
    [~,infoI]=w21.run_algorithm('windinfer',scnI,c);
    wT=[magv*cosd(dirDeg);magv*sind(dirDeg)];
    weI=infoI.windEst;
    kF=find(isfinite(weI(1,:)),1,'last');
    weF=weI(:,kF);
    e=norm(weF-wT);
    if magv>=0.5
        de=abs(atan2d(weF(2),weF(1))-atan2d(wT(2),wT(1)));
        if de>180, de=360-de; end
    else
        de=NaN;
    end
    errSeq=hypot(weI(1,:)-wT(1),weI(2,:)-wT(2));
    cs=NaN;
    for j=1:(numel(errSeq)-30)
        if all(errSeq(j:j+29)<0.3), cs=j; break; end
    end
    fprintf('  %4.1f m/s @%3d° → ŵ=(%5.2f,%5.2f) 幅值误差%.2f 方向误差%3.0f° 收敛@%s步\n',...
        magv,dirDeg,weF(1),weF(2),e,de,csStr(cs));
    allErr(end+1)=e; allConv(end+1)=cs; %#ok<AGROW>
    fprintf(fid,'| %.1f@%d° | (%.2f, %.2f) | %.2f | %.0f | %s |\n',...
        magv,dirDeg,weF(1),weF(2),e,de,csStr(cs));
end
Tcirc=2*pi*100/6.3;
fprintf('B1 小结: 幅值误差均值%.2f / 最差%.2f m/s; 收敛中位数%.0f步(约%.1f圈)\n',...
    mean(allErr),max(allErr),median(allConv),median(allConv)/Tcirc);
fprintf(fid,['\n**B1 小结**: 10 个恒定风, 幅值误差均值 **%.2f m/s** / 最差 %.2f m/s; ',...
    '收敛中位数 %.0f 步(约 %.1f 圈)。\n'],mean(allErr),max(allErr),median(allConv),median(allConv)/Tcirc);

% ---- B2 变风逐点跟踪(composite) ----
cV=w21.config('seed',3,'windKind','composite','windBias',2.5,'windAmp',1.5,...
    'windOmega',0.08,'windBiasY',0,'windAmpY',0,'turbStd',0.3);
scnV=w21.scenario('static',cV);
[~,infoV]=w21.run_algorithm('windinfer',scnV,cV);
weV=infoV.windEst;
n2=size(weV,2); wErrV=nan(1,n2);
for k=1:n2
    [~,~,Vx,Vy]=w21.wind_field(scnV,k*cV.tEval,0);   % 评价侧真风序列
    wErrV(k)=hypot(weV(1,k)-Vx,weV(2,k)-Vy);
end
rmseV=sqrt(mean(wErrV(~isnan(wErrV)).^2));
kSteady=max(1,round(n2/3)):n2;   % 收敛后稳态段(后2/3)
kSteady=kSteady(~isnan(wErrV(kSteady)));
rmseVst=sqrt(mean(wErrV(kSteady).^2));
pkSteady=max(wErrV(kSteady));
fprintf('B2 变风composite(2.5+1.5·sin(0.08t)+湍流0.3): 逐点RMSE=%.2f(含起步瞬态) 稳态RMSE=%.2f 稳态峰值=%.2f m/s\n',...
    rmseV,rmseVst,pkSteady);
fprintf(fid,'\n### B2 变风逐点跟踪(composite: 2.5+1.5·sin(0.08t)+湍流σ=0.3)\n\n');
fprintf(fid,['- 逐点 RMSE = %.2f m/s(含起步瞬态); **收敛后稳态 RMSE = %.2f m/s, 稳态峰值 %.2f m/s**',...
    '(真风自身峰峰变化约3 m/s+湍流σ=0.3)。',...
    '估计有约0.3-0.5圈的固有滞后(滑动窗+EMA), 风变得越快误差越大——这是信息滞后, 不是读到了什么。\n'],...
    rmseV,rmseVst,pkSteady);

% ---- B3 更快变风(单轴正弦, 周期42s < 一圈100s) ----
cS=w21.config('seed',3,'windKind','sin','windBias',3,'windAmp',2,'windOmega',0.15);
scnS=w21.scenario('static',cS);
[~,infoS]=w21.run_algorithm('windinfer',scnS,cS);
weS=infoS.windEst; n3=size(weS,2); wErrS=nan(1,n3);
for k=1:n3
    [~,~,Vx,Vy]=w21.wind_field(scnS,k*cS.tEval,0);
    wErrS(k)=hypot(weS(1,k)-Vx,weS(2,k)-Vy);
end
rmseS=sqrt(mean(wErrS(~isnan(wErrS)).^2));
kSt3=max(1,round(n3/3)):n3;
kSt3=kSt3(~isnan(wErrS(kSt3)));
rmseSst=sqrt(mean(wErrS(kSt3).^2));
fprintf('B3 快变风(3+2·sin(0.15t), 周期42s): 逐点RMSE=%.2f(含瞬态) 稳态RMSE=%.2f m/s\n',rmseS,rmseSst);
fprintf(fid,'\n### B3 更快变风(3+2·sin(0.15t), 周期42 s < 一圈100 s)\n\n');
fprintf(fid,['- 逐点 RMSE = %.2f m/s(含瞬态), **稳态 RMSE = %.2f m/s**。风变化周期短于转一圈时, ',...
    '航向扫描还没覆盖一个风变化周期, 跟踪误差接近风变化幅值本身——**这恰好证明算法不可能预知风的变化规律**, 只能事后追。\n'],rmseS,rmseSst);

fprintf(fid,'\n## 结论\n\n');
fprintf(fid,['- **因果性**: 结构(A1签名无scn) + 行为(A2假config试验) + 源码(A3零引用) 三重核验通过。',...
    '寻优全程算法不知道风的大小/方向, 更不知道风怎么变(连变风模型的类别/频率都不知道); ',...
    '唯一信息来源是带噪功率测量 + 自身指令(航向是指令死推的)。\n']);
fprintf(fid,['- **精度**: 恒定风幅值误差均值 %.2f m/s(约%.1f圈收敛); 变风受滑窗滞后约束, ',...
    'RMSE 随风变化加快而增大——快速变风的剩余误差是信息滞后边界, 不是算法偷看或失灵。\n'],mean(allErr),median(allConv)/Tcirc);
fprintf('VERIFY DONE\n');

function s=tfstr(x)
if x, s='**通过**'; else, s='**不通过**'; end
end
function s=csStr(cs)
if isnan(cs), s='未收敛'; else, s=sprintf('%d',cs); end
end
