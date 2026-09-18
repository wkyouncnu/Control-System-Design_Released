%% W14_03_run_simulink.m
%  14주차 실습 (3) : Simulink 로 실제와 추정을 나란히 보기
%
%  모델 W14_ObserverBased.slx 를 열어 보십시오.
%
%      >> open_system('W14_ObserverBased')
%
%  위아래 두 갈래입니다.
%
%    위쪽 = 실제 플랜트.  초기조건 x0 가 있다
%    아래쪽 = 관측기.     초기조건이 0 이다 — **아무것도 모른다**
%
%  그리고 **관측기로 들어가는 선은 u 와 y 두 개뿐입니다.**
%  진짜 상태는 아무 데도 연결되어 있지 않습니다. 직접 확인해 보십시오.
%
%  이 스크립트에서 답할 질문
%    Q1. 관측기가 정말 따라잡는가?                -> 2절
%    Q2. 관측기 극을 바꾸면 얼마나 빨리 따라잡나?  -> 3절
%    Q3. 센서 잡음이 있으면 어떻게 되는가?         -> 4절
%
%  돌리면 나오는 것
%    표 3개 + 그림 3장. Simulink 를 8 번 부릅니다
%    걸리는 시간 : 약 25 초
%
%  대응하는 강의노트 : W14_LectureNote.mlx
%
%  제어시스템설계 14주차 | 충남대학교 자율운항시스템공학과

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

model = 'W14_ObserverBased';
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

[Gp, p] = plant_dcmotor('position');
A_mat = p.A;  B_mat = p.B;  C_mat = p.C;
n     = size(A_mat, 1);
x0    = [0.5; 0; 0];        % 실제 플랜트는 0.5 rad 기울어진 채로 시작
u_amp = 0;                  % 입력은 0. 관측기가 따라잡는 것만 본다
noise_pwr = 0;              % 잡음 없음
t_end = 0.6;

p_ctrl = [-8 -10 -12];
L_obs  = place(A_mat', C_mat', 3*p_ctrl)';

fprintf('=== 1. 설정 ===\n');
fprintf('  실제 플랜트 초기값 : %s\n', mat2str(x0.'));
fprintf('  관측기 초기값      : %s   <- 아무것도 모른다\n', mat2str(zeros(1,n)));
fprintf('  관측기 극          : %s\n', mat2str(3*p_ctrl));
fprintf('  L = %s\n\n', mat2str(round(L_obs.', 1)));

%% 2. 관측기가 따라잡는가
%
%  관측기는 x(0) 를 모릅니다. 그런데도 몇 십 ms 만에 맞춰 냅니다.

out = sim(model, 'StopTime', num2str(t_end));

% [주의] 가변 스텝 솔버라 시간 간격이 균일하지 않습니다.
%        두 신호의 시간축도 서로 다를 수 있으므로 균일 격자로 옮깁니다.
tu = (0:0.0005:t_end)';
Xr = interp1(out.x_real.Time, out.x_real.Data, tu);
Xh = interp1(out.x_hat.Time,  out.x_hat.Data,  tu);

nm = {'각도 (잴 수 있다)', '각속도 (못 잰다)', '전류 (못 잰다)'};
fprintf('=== 2. 관측기의 수렴 ===\n');
fprintf('  %-22s  최대 오차   2 %% 이내 도달[s]\n', '상태');
fprintf('  %-22s  ---------   ---------------\n', '----');
for i = 1:n
    e  = Xr(:,i) - Xh(:,i);
    em = max(abs(e));
    k  = find(flipud(abs(e)) > 0.02*em, 1, 'first');
    if isempty(k), tk = 0; else, tk = tu(end - k + 1); end
    fprintf('  %-22s  %9.3f   %15.3f\n', nm{i}, em, tk);
end
fprintf('\n');

figure('Name', '실제와 추정');
tiledlayout(2, 2, 'TileSpacing', 'compact');
for i = 1:2
    nexttile
    plot(tu, Xr(:,i), 'LineWidth', 2.6); hold on; grid on;
    plot(tu, Xh(:,i), '--', 'LineWidth', 2.4);
    xlabel('시간 [s]'); ylabel(nm{i});
    legend('실제 x', '관측기의 추정 xhat', 'Location', 'best');
    title(nm{i});
end
for i = 1:2
    nexttile
    plot(tu, Xr(:,i) - Xh(:,i), 'LineWidth', 2.4, 'Color', [0.85 0.2 0.15]);
    grid on; yline(0, 'k--');
    xlabel('시간 [s]'); ylabel(sprintf('오차 e_%d', i));
    title('추정오차는 (A - LC) 의 고유값으로 줄어든다');
end

fprintf('  **각속도계도 전류계도 없는데 맞춰 냅니다.**\n');
fprintf('  관측기가 받는 것은 u 와 y (각도) 뿐입니다.\n\n');

%% 3. 관측기 극을 바꾸면
%
%  제어기 극의 몇 배로 잡을지를 바꿔 가며 돌립니다.

mults = [1 2 3 5];
figure('Name', '관측기 속도');
tiledlayout(1, 2, 'TileSpacing', 'compact');
E1 = cell(size(mults));

fprintf('=== 3. 관측기 극의 배수 ===\n');
fprintf('     배수     |L|      각도 오차 2 %% 도달[s]\n');
fprintf('   -------  ---------  ---------------------\n');
for j = 1:numel(mults)
    L_obs = place(A_mat', C_mat', mults(j)*p_ctrl)';        %#ok<NASGU>
    out   = sim(model, 'StopTime', num2str(t_end));
    Xr_   = interp1(out.x_real.Time, out.x_real.Data, tu);
    Xh_   = interp1(out.x_hat.Time,  out.x_hat.Data,  tu);
    E1{j} = Xr_(:,1) - Xh_(:,1);
    em    = max(abs(E1{j}));
    k     = find(flipud(abs(E1{j})) > 0.02*em, 1, 'first');
    if isempty(k), tk = 0; else, tk = tu(end - k + 1); end
    fprintf('   %7d  %9.0f  %21.3f\n', mults(j), norm(L_obs), tk);
end
fprintf('\n');

nexttile
hold on; grid on;
for j = 1:numel(mults)
    plot(tu, E1{j}, 'LineWidth', 2.2, ...
         'DisplayName', sprintf('제어기 극의 %d 배', mults(j)));
end
yline(0, 'k--', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('각도 추정오차');
xlim([0 0.4]);
legend('Location', 'northeast');
title('빠르게 잡을수록 빨리 따라잡는다');

%% 4. 센서 잡음이 있으면 — 오늘의 맞바꿈
%
%  **여기가 오늘 가장 중요한 절입니다.**
%
%  3절만 보면 "관측기는 빠를수록 좋다" 로 읽힙니다. 잡음을 넣어 봅시다.

noise_pwr = 1e-9;           % 센서 잡음
u_amp     = 1;              % 입력도 넣는다
t_end     = 0.5;
tu2 = (0:0.0005:t_end)';

fprintf('=== 4. 잡음이 있을 때 ===\n');
fprintf('     배수     |L|      추정 각속도의 떨림(표준편차)\n');
fprintf('   -------  ---------  ----------------------------\n');

nexttile
hold on; grid on;
V = cell(size(mults));
for j = 1:numel(mults)
    L_obs = place(A_mat', C_mat', mults(j)*p_ctrl)';        %#ok<NASGU>
    out   = sim(model, 'StopTime', num2str(t_end));
    Xr_   = interp1(out.x_real.Time, out.x_real.Data, tu2);
    Xh_   = interp1(out.x_hat.Time,  out.x_hat.Data,  tu2);
    V{j}  = Xh_(:,2);
    resid = Xh_(:,2) - Xr_(:,2);
    plot(tu2, Xh_(:,2), 'LineWidth', 1.6, ...
         'DisplayName', sprintf('%d 배 (떨림 %.1e)', mults(j), std(resid)));
    fprintf('   %7d  %9.0f  %28.2e\n', mults(j), norm(L_obs), std(resid));
end
plot(tu2, Xr_(:,2), 'k--', 'LineWidth', 2.2, 'DisplayName', '실제 각속도');
xlabel('시간 [s]'); ylabel('추정 각속도 [rad/s]');
legend('Location', 'northwest');
title('빠르게 만들수록 잡음으로 떨린다 — 공짜가 아니다');

fprintf('\n');
fprintf('  --> 3절과 4절을 함께 보십시오.\n');
fprintf('      빠르면 잘 따라잡지만 잡음도 그만큼 크게 증폭합니다.\n');
fprintf('      그래서 관례가 **2~5배**인 것입니다. 그보다 크면 잡음이 이깁니다.\n\n');

fprintf('  13주차와의 대칭\n');
fprintf('    13주차 : 제어기 극을 왼쪽으로 -> **제어입력**이 커진다\n');
fprintf('    14주차 : 관측기 극을 왼쪽으로 -> **잡음 증폭**이 커진다\n');
fprintf('    두 대가가 정확히 짝을 이룹니다. 이것도 쌍대성입니다.\n\n');

%% 5. 직접 해 볼 것
%
%  - 모델을 열어 **관측기로 들어가는 선이 u 와 y 뿐**인지 확인하십시오
%  - `x0` 를 [0; 1; 0] 으로 바꾸면 (각속도만 틀리면) 어떻게 따라잡습니까?
%  - `noise_pwr` 을 1e-8 로 키우고 5 배 관측기를 돌려 보십시오
%  - 관측기 블록의 A 를 `A_mat` 로만 두면 (L 을 지우면) 어떻게 됩니까?
%    이것이 **열린 관측기**이고, 왜 안 되는지 보여 줍니다

fprintf('=== 정리 ===\n');
fprintf('  1. 관측기는 u 와 y 만으로 상태를 만들어 낸다\n');
fprintf('  2. 빠르게 잡을수록 빨리 따라잡는다\n');
fprintf('  3. 그런데 잡음도 그만큼 증폭한다. 관례는 2~5배\n');
fprintf('  --> 이것으로 한 학기가 끝났습니다. 수고하셨습니다.\n');
