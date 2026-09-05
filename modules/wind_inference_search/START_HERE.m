%START_HERE 任务2.1风速推断寻优：一键打开三模块动态演示面板。
% 空速=地速−风速(地速6+顺风3→空速3) × 风不影响运动(只影响功率)
% × 空速曲线固定/地速曲线顺风右移逆风左移 × 七种可选风场 × 曲线case标定。
root=fileparts(mfilename('fullpath'));
addpath(root);
launch_2_1_demo('on');
