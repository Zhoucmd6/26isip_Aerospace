function [log, info] = run_algorithm(name, scn, c)
%RUN_ALGORITHM 任务7调度器：在实际约束对象上用指定策略跑完整一幕。
% name:
%   'openloop'  开环控制基线(用户需求4): 固定速度平飞, 量化算法MOE提升
%   'tracker'   任务1平移跟踪基线(Brent+迟滞监测, 原样移植)
%   'esc'       连续极值寻优基线(原样移植)
%   'spsa'      随机同步扰动逼近(任务6新增, 原样移植)
%   'bayes'     贝叶斯代理寻优(任务6新增, 原样移植)
%   'qnewton'   割线牛顿寻优(任务6新增推荐, 原样移植)
%   'gtrack'    小行程交替dither梯度跟踪(任务7新增, 见gtrack_run)
%   'est'       在线风EKF估计+解析调度跟踪(任务7模型法, 对照用, 见est_run)
%   'windinfer' 功率调制风矢量推断+闭式地速调度(任务2.1主角, 见windinfer_run):
%               无探针dither, 激励来自转圈航向扫描; 窗长自适应+风况判定
%   'known'     已知风oracle参照(评价侧上界, 非因果策略, 同任务6 fixed定位)
% 所有算法共享同一条指令就位规则(w21.settled_q): 横比只反映策略差异。
% 算法侧白名单：不传场景真值/曲线/噪声/种子(红线1); 接口与任务6一致
% (plant.q(v,tag)), 对象侧升级不改控制器接口(红线2)。
p=c;   % 统一config即白名单(对象真值由plant持有, 不经p传递)
plant=w21.make_plant(scn,c);
n=c.duration;
switch name
    case 'openloop'
        info=w21.openloop_run(plant,p,n);
    case 'tracker'
        info=w21.tracker_run(plant,p,n);
    case 'esc'
        info=w21.esc_run(plant,p,n);
    case 'spsa'
        info=w21.spsa_run(plant,p,n);
    case 'bayes'
        info=w21.bayes_run(plant,p,n);
    case 'qnewton'
        info=w21.qnewton_run(plant,p,n);
    case 'gtrack'
        info=w21.gtrack_run(plant,p,n);
    case 'est'
        info=w21.est_run(plant,p,n);
    case 'windinfer'
        info=w21.windinfer_run(plant,p,n);
    case 'known'
        info=w21.known_run(plant,p,n,scn);
    otherwise
        error('w21:RunAlgorithm','Unknown algorithm: %s',name);
end
info.name=name; info.scenario=scn.kind; info.seed=c.seed;
log=plant.table();
end
