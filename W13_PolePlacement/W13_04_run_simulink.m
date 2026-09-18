%% W13_04_run_simulink.m
%  13주차 실습 (4) : Simulink 로 극배치와 포화를 확인한다
%
%  모델 W13_PolePlacement.slx 를 열어 보십시오.
%
%      >> open_system('W13_PolePlacement')
%
%  지금까지의 모델과 딱 두 가지가 다릅니다.
%
%    (1) 되먹임 경로의 Gain 블록에 **스칼라가 아니라 행벡터 K** 가 들어 있다
%    (2) 플랜트의 C 가 **단위행렬**이다 (상태를 전부 뽑는다)
%
%  (2) 가 상태궤환의 전제입니다. **상태를 전부 알아야 쓸 수 있습니다.**
%  이 전제를 깨는 것이 14주차입니다.
%
%  이 스크립트에서 답할 질문
%    Q1. Simulink 결과가 MATLAB 계산과 같은가?      -> 2절
%    Q2. 극을 왼쪽으로 보내면 제어입력이 어떻게 되나? -> 3절
%    Q3. 구동기가 못 내면 무슨 일이 생기나?          -> 4절
%
%  돌리면 나오는 것
%    표 3개 + 그림 3장. Simulink 를 11 번 부릅니다
%    걸리는 시간 : 약 30 초
%
%  대응하는 강의노트 : W13_LectureNote.mlx
%
%  제어시스템설계 13주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 경로 자동 등록 — setup_path 를 아직 안 했어도 알아서 잡습니다
%  (이 블록은 실습 내용과 상관없습니다. 지우지 마십시오.)
if isempty(which('plant_msd'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end

model = 'W13_PolePlacement';
here  = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
if ~bdIsLoaded(model), load_system(fullfile(here, [model '.slx'])); end

%% 0. 이 모델은 어떤 블록으로 되어 있나
%
%  모델을 열기 전에 안에 무엇이 들어 있는지 먼저 읽고 들어갑니다.
%  블록 하나가 무슨 계산을 하는지, 그리고 왜 하필 거기 있는지를
%  아래 표가 한 줄씩 알려 줍니다. 표를 소리 내어 읽으면서
%  모델 창에서 그 블록을 하나씩 짚어 보십시오.
%
%  같은 표가 .slx 안에도 주석으로 붙어 있습니다. 두 곳의 글은 항상 같습니다.
%  원본은 common/model_blocks.m 한 곳뿐이고, 나머지는 모두 그것을 불러다 씁니다.

model_blocks(model, 'print');

%% 1. 파라미터 설정
%
%  블록에는 숫자 대신 변수 이름이 적혀 있습니다.
%  여기서 값을 정하고 sim 을 부르면 그 값으로 돕니다.

[Gp, p] = plant_dcmotor('position');
A_mat = p.A;  B_mat = p.B;
x0    = zeros(size(A_mat,1), 1);
r_amp = 1;
t_end = 1.5;

p_des = [-8 -10 -12];
K_fb  = place(A_mat, B_mat, p_des);
Kr    = 1/dcgain(ss(A_mat - B_mat*K_fb, B_mat, p.C, p.D));
u_lim = 1e6;                      % 사실상 포화 없음

fprintf('=== 1. 설정 ===\n');
fprintf('  극배치 목표 : %s\n', mat2str(p_des));
fprintf('  K  = %s\n', mat2str(round(K_fb, 3)));
fprintf('  Kr = %.2f\n\n', Kr);

%% 2. Simulink 와 MATLAB 이 같은가
%
%  같은 설계를 두 방식으로 돌려 겹쳐 봅니다.
%  **이 확인을 매 주차마다 하는 이유** — 블록을 잘못 이었거나 부호를
%  반대로 놓으면 여기서 바로 드러나기 때문입니다.

out = sim(model, 'StopTime', num2str(t_end));
ts  = out.x_sim;

% [주의] 가변 스텝 솔버라 out 의 시간 벡터는 **간격이 균일하지 않습니다.**
%        step 은 균일한 시간 벡터만 받으므로 그대로 넣으면 오류가 납니다.
%        균일 격자를 따로 만들고 interp1 로 옮겨 붙입니다.
t_u = (0:0.002:t_end)';
x_s = interp1(ts.Time, ts.Data, t_u);
y_m = step(ss(A_mat - B_mat*K_fb, B_mat*Kr, p.C, p.D), t_u);

fprintf('=== 2. Simulink 대 MATLAB ===\n');
fprintf('  최대 차이 : %.3e\n', max(abs(x_s(:,1) - y_m)));
fprintf('  --> 같습니다. 모델이 제대로 이어졌습니다.\n\n');

figure('Name', 'Simulink 대 MATLAB');
plot(t_u, x_s(:,1), 'LineWidth', 3); hold on; grid on;
plot(t_u, y_m, '--', 'LineWidth', 2);
yline(1, 'k:', 'LineWidth', 1.4);
xlabel('시간 [s]'); ylabel('각도 [rad]');
legend('Simulink', 'MATLAB step', '목표', 'Location', 'southeast');
title(sprintf('두 결과가 겹친다 (최대 차이 %.1e)', max(abs(x_s(:,1) - y_m))));

%% 3. 극을 왼쪽으로 보내면
%
%  극점 위치를 바꿔 가며 Simulink 를 반복 호출합니다.
%  응답과 제어입력을 함께 봅니다.

a_list = [4 8 12 16];
figure('Name', '극 위치별 응답과 제어입력');
tiledlayout(1, 2, 'TileSpacing', 'compact');
Yc = cell(size(a_list));  Uc = cell(size(a_list));  Tc = cell(size(a_list));

fprintf('=== 3. 극 위치별 ===\n');
fprintf('     극점            |K|     정착시간[s]   최대 전압[V]\n');
fprintf('   ------------  --------  ------------  -------------\n');
for i = 1:numel(a_list)
    a     = a_list(i);
    K_fb  = place(A_mat, B_mat, [-a -a-2 -a-4]);                 %#ok<NASGU>
    Kr    = 1/dcgain(ss(A_mat - B_mat*K_fb, B_mat, p.C, p.D));   %#ok<NASGU>
    out   = sim(model, 'StopTime', num2str(t_end));
    Tc{i} = out.x_sim.Time;
    Yc{i} = out.x_sim.Data(:,1);
    Uc{i} = out.u_sim.Data;
    si    = stepinfo(Yc{i}, Tc{i}, 1);
    fprintf('   %3.0f %3.0f %3.0f     %8.1f  %12.3f  %13.1f\n', ...
            -a, -a-2, -a-4, norm(K_fb), si.SettlingTime, max(abs(Uc{i})));
end
fprintf('\n');

nexttile
hold on; grid on;
for i = 1:numel(a_list)
    plot(Tc{i}, Yc{i}, 'LineWidth', 2.2, ...
         'DisplayName', sprintf('극점 %d 근처', -a_list(i)));
end
yline(1, 'k--', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('각도 [rad]'); ylim([0 1.2]);
legend('Location', 'southeast');
title('왼쪽으로 보낼수록 빨라진다');

nexttile
hold on; grid on;
for i = 1:numel(a_list)
    plot(Tc{i}, Uc{i}, 'LineWidth', 2.2, ...
         'DisplayName', sprintf('최대 %.0f V', max(abs(Uc{i}))));
end
yline(0, 'k:', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('제어입력 [V]');
xlim([0 0.3]);
legend('Location', 'northeast');
title('그런데 전압이 폭증한다');

%% 4. 구동기가 못 내면 — 포화
%
%  **오늘의 마지막이자 가장 실무적인 절입니다.**
%
%  3절에서 본 전압은 수백 V 였습니다. 실제 드라이버는 24 V 정도입니다.
%  그럼 무슨 일이 생길까요? Saturation 블록을 켜고 봅니다.

a     = 12;
K_fb  = place(A_mat, B_mat, [-a -a-2 -a-4]);
Kr    = 1/dcgain(ss(A_mat - B_mat*K_fb, B_mat, p.C, p.D));

lims = [1e6 200 60 24];
figure('Name', '구동기 포화');
tiledlayout(1, 2, 'TileSpacing', 'compact');
YL = cell(size(lims));  UL = cell(size(lims));  TL = cell(size(lims));

fprintf('=== 4. 구동기 한계별 ===\n');
fprintf('     한계[V]   정착시간[s]   오버슈트[%%]   실제 최대 전압[V]\n');
fprintf('   ---------  ------------  ------------  ------------------\n');
for i = 1:numel(lims)
    u_lim = lims(i);                                             %#ok<NASGU>
    out   = sim(model, 'StopTime', '2');
    TL{i} = out.x_sim.Time;
    YL{i} = out.x_sim.Data(:,1);
    UL{i} = out.u_sim.Data;
    si    = stepinfo(YL{i}, TL{i}, 1);
    if lims(i) > 1e5, nmv = Inf; else, nmv = lims(i); end
    fprintf('   %9.0f  %12.3f  %12.1f  %18.1f\n', ...
            nmv, si.SettlingTime, si.Overshoot, max(abs(UL{i})));
end
fprintf('\n');

nexttile
hold on; grid on;
for i = 1:numel(lims)
    if lims(i) > 1e5, nm = '포화 없음'; else, nm = sprintf('%d V 한계', lims(i)); end
    plot(TL{i}, YL{i}, 'LineWidth', 2.2, 'DisplayName', nm);
end
yline(1, 'k--', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('각도 [rad]');
legend('Location', 'southeast');
title('한계가 낮을수록 느려지고 더 튄다');

nexttile
hold on; grid on;
for i = 1:numel(lims)
    if lims(i) > 1e5, nm = '포화 없음'; else, nm = sprintf('%d V 한계', lims(i)); end
    plot(TL{i}, UL{i}, 'LineWidth', 2.2, 'DisplayName', nm);
end
yline(0, 'k:', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('제어입력 [V]');
xlim([0 0.5]); ylim([-100 250]);
legend('Location', 'northeast');
title('평평하게 잘린 구간이 포화된 시간이다');

fprintf('  읽는 법\n');
fprintf('    제어입력 그림에서 **평평하게 잘린 구간**이 포화된 시간입니다.\n');
fprintf('    그 시간 동안 제어기는 "더 주라" 고 하는데 구동기가 못 냅니다.\n');
fprintf('    그래서 응답이 느려지고 오버슈트가 커집니다.\n\n');
fprintf('  중요 — 극배치는 **포화를 전혀 모릅니다.**\n');
fprintf('    설계를 마쳤으면 반드시 제어입력을 확인하고,\n');
fprintf('    구동기 한계 안에 들어오도록 극점을 다시 잡으십시오.\n\n');

%% 5. 직접 해 볼 것
%
%  - `u_lim` 을 12 로 줄여 보십시오. 여전히 목표에 도달합니까?
%  - `x0` 를 [0.5; 0; 0] 으로 두면 (처음부터 0.5 rad 기울어져 있으면)
%    초기 제어입력이 얼마나 됩니까?
%  - `Kr` 을 1 로 두고 돌리면 어디에 수렴합니까? (W13_02 의 1절)
%  - 극점을 [-30 -32 -34] 로 두고 24 V 한계를 걸면 어떻게 됩니까?

fprintf('=== 정리 ===\n');
fprintf('  1. Simulink 와 MATLAB 결과가 일치한다 (모델이 맞다)\n');
fprintf('  2. 극을 왼쪽으로 보낼수록 빨라지지만 전압이 폭증한다\n');
fprintf('  3. 구동기 한계에 걸리면 설계대로 안 움직인다\n');
fprintf('  --> 그런데 오늘 내내 **상태를 전부 안다고 가정**했습니다.\n');
fprintf('      실제로는 각도만 잽니다. 14주차의 관측기로 갑니다.\n');
