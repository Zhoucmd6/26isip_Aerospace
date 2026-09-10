# 2026-09-10 王健祺（ZCode 协助）：T3.6 平台数据源对等性修复 + 10 倍窗验收

## 做了什么
- 触发：王健祺平台后端演示发现 sweepcal 拟合出界/寻优失败、purerl_off 恒速飞行、purerl_on 不如本地——触发接手方案 D3 条件阶段 5（就位语义深化）与数据源一致性专项。
- 修复 N1–N8（详见 docs/T36_PLATFORM_PARITY_FINDINGS_20260910.md）：q() 返回功率归一化补漏、就位委托制（D3 阶段 5 方案 1）、RL 更新门放行、purerl 预训练数据源修正+缓存模型、fit_curve_wind 抗退化（帧坍缩判据+谷底内点）、扫频扩展 [2,13.5] 与探针 150→100、demo 显示随数据源切换（平台真实瓦数）、部署路径多候选探测。
- 插播：v2 演示文稿 17–19 页演讲稿备注（中英对照，另交付 _with_notes 副本）。

## 验收（9000s=10× 窗，B=2.5 默认复合风，seed=11）——最终口径见下"深夜轮"
- openloop 4.48% | purerl_off 0.54% | purerl_on 1.60% | sweepcal 1.80% —— 全部优于开环，验收达标。
- sweepcal B=3.5（用户配置）9000s：5.02%（修复前 25%、û*=11.76 发散）。
- 回归：单元 52/52 全绿（M1 锚点按就位委托语义重写）。
- 证据：docs/evidence/platform_link/acceptance_9000s_20260910/（5 臂 CSV + 学费分解日志）。
- （更正：上述 purerl_off 0.54% 为 ψ̂ 冻结自锁假象，见深夜轮 N9；最终验收以 arm9k_*.csv 为准。）

## 困扰与遗留
平台四大困扰（就位学费/联合辨识退化边界/航向死推相位漂移/MATLAB 运行时崩溃）与 B=3.5 purerl 对等性、多种子统计等遗留项见发现文档 §3–§4；purerl 平台对等性建议 M4 处理（路线图既有条款）。

## 深夜轮（同日）：ψ̂ 冻结根因钉死 + 守卫统一 + 修复后验收重跑（最终验收口径）
- **N9 根因**：purerl_off"百余步后速度不变"并非算法不收敛——平台 plant.count() 浮点漂移使重复指令步 sUsed=0.999…<1，`for j=1:sUsed` 零迭代（冒号空区间），ψ̂ 停止推进→分箱锁定→指令恒定的自锁死锁。插桩（ADVDBG 逐步打印 + psiHist 逐谱写入）在 k=71→72 处同参数增量归零钉死。10 处全量改为 sUsed 直乘（sweepcal/hybrid/rl/purerl/purerl_pre/est/windinfer）。
- **N10 方案 B**：hybrid/windinfer 的 disc<0 兜底从 `max(q,0)` 换成与 sweepcal 一致的"保持上一可行指令+0.8û*托底"；sweepcal 保持值同样加托底。
- **缓存重生成**：旧缓存暖机受同一缺陷影响（仅少数分箱被真实训练）；解冻后 purerl_off 暴涨 14.38%（逐箱查表飞出垃圾分箱，且证明旧 0.54% 是恒速假象）。按修复后语义重生成缓存（muB：逆风段 2.3–3.8、顺风段 7.2–7.5，与闭式调度理论形状吻合），purerl_off 降至 **−1.21%**（全场最优）、purerl_on 1.01%。
- 快检：600s purerl_off 334/334 步推进、12 分箱全活跃（修复前尾段 300 步恒值）；回归 52/52。
- **最终验收（arm9k_*.csv，全部优于开环 4.48%）**：purerl_off −1.21% | sweepcal B2.5 0.40% | purerl_on 1.01% | sweepcal B3.5 1.42%。sweepcal 较修复前再改善 4.5×/3.5×（ψ̂ 全步推进提升重拟合与风修正的方位角分辨率）。
- 证据：acceptance_9000s_20260910/ 新增 arm9k_*.csv 五臂 + psi_trace_purerl_off_600s.csv + 旧五臂更名 *_preN9.csv 留证；重生成的 pretrain_platform_composite.mat（1KB）首次入库（modules/platform_link/pretrained/）。
- 演示文稿：新版 13/14 页中英对照演讲稿备注；修复 17 页备注误为 16 页重复。
