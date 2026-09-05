# 风速语义修正模块：空速 = 地速 − 风 × 风不影响运动 × 空速-功率曲线固定

本地编号：**1.11**（原 task10，本地文件夹 `speed_esc_matlab/1.11_wind_semantics`，内部包 `+w10` 与脚本名保持历史原名）。
本模块是算法线**当前的风速语义参考实现**：其余算法线模块（realistic_constraints_search / curve_case_calibration / wind_model_library）仍为局部加号约定（u=|v·t̂+w|），接入统一线前必须按本模块口径适配（接口字典 0.3：`v_air = v_ground − wind`）。

项目组：周航正、霍奕茗、于跃、叶安、王健祺
文件负责人：王健祺
主要撰写：王健祺
AI协助：ZCode（对象实现、测试与检查脚本、验证实验）
审核：待项目组审核

## 1. 语义修正（用户口径 2026-09-04，对象物理与此严格一致）

1. **风不会把飞机吹跑**：运动学纯地速（ψ'=v_ground/R），风只通过"空速查曲线"影响功率；
2. **空速 = 地速 − 风速**（矢量差）：地速向右 6 m/s、顺风向右 3 m/s → 空速向右 3 m/s；
   与接口字典 0.3 的 `v_air=v_ground−wind` 统一约定一致；
3. **先验速度-功率曲线是无风标定的空速-功率曲线** → 严格固定不移动；
   地速-功率曲线随风平移：顺风右移、逆风左移；仪表盘显示地速；
4. 解析最优（地速口径）：`v* = q + sqrt(q² + u*² − |w|²)`，`q = t̂·w`（顺风为正）。

## 2. 物理与继承

- 继承 realistic_constraints_search 的四项实际约束（物理转弯半径 ψ'=v/R、通信时延 FIFO
  0–0.5 s、加速度限幅 2 m/s²、开环固定基线）；
- 继承 curve_case_calibration 的标定曲线（DJI Mavic Pro 锚点：悬停 103.7 W、谷底
  6.3 m/s、P(20)=134.5 W；谷底=悬停的 95/90/85% 三 case）；
- 继承 wind_model_library 的七种风场模型库（const/sin/软边方波/三角/OU湍流/复合/扇区）；
- 日志新增评价侧列：airspeed/windX/windY（算法侧不可读，红线1）。

## 3. 验收状态

- `tests_task10`：19/19 通过（含空速恒等式 |v·t̂−w| 1e-9、闭式最优与日志 1e-9 一致、
  用户口径顺风/逆风例子、τ=0 对照口径）；
- `run_task10_checks`：5/5 门槛通过；
- 3×3 验证表（悬停/匀速转圈@u\*/变速转圈 × 无风/恒定风/变风）：见
  [`../docs/evidence/wind_semantics_correction/table_3x3.md`](../docs/evidence/wind_semantics_correction/table_3x3.md)。

## 4. ⚠️ 有效性边界（项目组特别标注）

- 本模块给出的是**修正后的语义参考实现**；三个前序模块（task7-9 线）的加号约定
  **尚未批量适配**，其历史证据在新口径下需先做 w→−w 变换方可引用；
- 曲线为 DJI 文献代理、风场参数为文献典型值，均未实测校准（与 task8/9 同一局限）；
- 全部结论为 proxy 等级代理口径，不支持真实 X8 节能表述（红线3）。

## 5. 运行

```matlab
cd wind_semantics_correction; addpath(pwd);
tests_task10          % 19 项单元测试
run_task10_checks     % 5 项门槛 + 证据报告
table_3x3             % 3×3 验证表 → docs/table_3x3.md
launch_task10_demo    % 三模块动态演示面板
```
