%% W06_03_run_simulink.m
%  6주차 실습 (3) : 근궤적으로 고른 이득을 Simulink 로 검증하기
%
%  이번 실습의 핵심 메시지
%
%      근궤적은 선형 이론이다. 포화를 모른다.
%      선형 이론으로 고른 이득이 실제로도 통하는지는 따로 확인해야 한다.
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W06_Rlocus_Verify')
%  기본값은 포화가 없는 상태입니다. u_lim 을 줄이면 달라집니다.
%
%  제어시스템설계 6주차 | 충남대학교 자율운항시스템공학과

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
s = tf('s');

model = 'W06_Rlocus_Verify';

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

%% 1. 근궤적으로 이득 고르기
%
%  이번에는 사양을 조금 느슨하게 잡아 비례제어로 만족 가능한 문제를 풉니다.
%
%      오버슈트 40 % 이하, 정착시간 6 초 이하
%
%  W06_02 에서는 사양이 빡세서 비례제어로 불가능했습니다.
%  여기서는 가능한 범위를 골라 검증에 집중합니다.

[G, p] = plant_dcmotor('position');
[numG, denG] = tfdata(G, 'v');       %#ok<ASGLU>  <- 모델이 사용

P_OS = 40;  ts_req = 6;
[zeta_min, wn_min] = spec2pole(P_OS, ts_req);

% 사양을 만족하는 이득 범위를 훑어 찾습니다
K_scan = linspace(1, 110, 400);
ok = false(size(K_scan));
for i = 1:numel(K_scan)
    ii = stepinfo(feedback(K_scan(i)*G, 1));
    ok(i) = (ii.Overshoot <= P_OS) && (ii.SettlingTime <= ts_req);
end

fprintf('=== 이득 선정 ===\n');
fprintf('  요구 : 오버슈트 %.0f %% 이하, 정착시간 %.0f s 이하\n', P_OS, ts_req);
if any(ok)
    K = K_scan(find(ok, 1, 'last'));
    fprintf('  만족 범위 : K = %.1f ~ %.1f\n', ...
            K_scan(find(ok,1)), K_scan(find(ok,1,'last')));
    fprintf('  선택 : K = %.1f (외란 억제를 위해 큰 쪽)\n', K);
else
    K = 20;
    fprintf('  만족하는 K 가 없어 K = %.1f 로 진행합니다.\n', K);
end

info_lin = stepinfo(feedback(K*G, 1));
fprintf('  선형 이론 예측 : 오버슈트 %.1f %%, 정착시간 %.2f s\n\n', ...
        info_lin.Overshoot, info_lin.SettlingTime);

%% 2. 포화 없이 Simulink 검증
%
%  먼저 포화를 아주 크게 잡아 사실상 없는 상태로 돌립니다.
%  이때는 선형 이론과 같은 결과가 나와야 합니다.

r_amp = 1;                 % 목표 각도 [rad]
t_end = 6;
u_lim = 1e6;               % 포화 없음
t = (0:0.002:t_end)';

out_nosat = sim(model);
y_nosat = interp1(out_nosat.y_sim.Time, squeeze(out_nosat.y_sim.Data), t);
u_nosat = interp1(out_nosat.u_sim.Time, squeeze(out_nosat.u_sim.Data), t);

y_lin = step(r_amp*feedback(K*G,1), t);

fprintf('=== 포화 없을 때 : Simulink vs MATLAB ===\n');
fprintf('  최대 차이 : %.3e rad\n', max(abs(y_nosat - y_lin)));
fprintf('  --> 일치합니다. 포화가 없으면 선형 이론이 정확합니다.\n');
fprintf('  이때 필요한 최대 제어입력 : %.1f V\n\n', max(abs(u_nosat)));

%% 3. 포화를 넣으면
%
%  실제 모터 드라이버가 낼 수 있는 전압에는 한계가 있습니다.
%  흔히 12 V, 24 V, 48 V 를 씁니다.
%
%  2절에서 필요하다고 계산된 제어입력과 비교해 보십시오.
%  한계보다 크면 포화가 걸립니다.

u_limits = [1e6, 48, 24, 12];
labels   = {'포화 없음', '48 V', '24 V', '12 V'};

figure('Name','포화의 영향');
tiledlayout(2,1,'TileSpacing','compact');

Y = zeros(numel(t), numel(u_limits));
U = zeros(numel(t), numel(u_limits));

fprintf('=== 포화 한계별 결과 ===\n');
fprintf('  한계        오버슈트[%%]  정착시간[s]  최대 제어입력[V]\n');
fprintf('  ----------  ----------  -----------  ----------------\n');
for i = 1:numel(u_limits)
    u_lim = u_limits(i);             %#ok<NASGU>  <- 모델이 이 값을 읽습니다
    out = sim(model);
    Y(:,i) = interp1(out.y_sim.Time, squeeze(out.y_sim.Data), t);
    U(:,i) = interp1(out.u_sim.Time, squeeze(out.u_sim.Data), t);

    ii = stepinfo(Y(:,i), t, r_amp);
    fprintf('  %-10s  %10.1f  %11.2f  %16.1f\n', ...
            labels{i}, ii.Overshoot, ii.SettlingTime, max(abs(U(:,i))));
end
fprintf('\n');

nexttile
for i = 1:numel(u_limits)
    plot(t, Y(:,i), 'LineWidth', 2); hold on;
end
yline(r_amp, 'k--', 'LineWidth', 1.5); grid on;
ylabel('각도 [rad]');
title(sprintf('K = %.1f 일 때 포화 한계에 따른 응답', K));
legend([labels, {'목표값'}], 'Location','southeast');

nexttile
for i = 1:numel(u_limits)
    plot(t, U(:,i), 'LineWidth', 2); hold on;
end
grid on; xlabel('시간 [s]'); ylabel('제어입력 u [V]');
title('제어입력 (포화로 잘린 모습이 보인다)');

%% 4. 무엇을 읽어야 하는가
%
%  위 표와 그림에서 확인할 것
%
%      (1) 포화가 걸리면 오버슈트와 정착시간이 선형 예측과 달라진다
%      (2) 한계가 낮을수록 응답이 느려진다
%      (3) 제어입력 그래프가 위아래로 평평하게 잘린 것이 포화다
%
%  왜 느려지는가
%
%      제어기는 "이만큼 전압을 주라" 고 명령하는데 구동기가 그만큼 못 냅니다.
%      결국 실제로 들어가는 힘이 작아져 응답이 느려집니다.
%
%  중요한 교훈
%
%      근궤적으로 K 를 골랐다면 반드시 제어입력을 확인해야 합니다.
%      제어입력이 구동기 한계를 넘으면 그 설계는 종이 위에서만 맞습니다.
%
%  실무 절차
%
%      1) 근궤적으로 K 를 고른다
%      2) 그때의 최대 제어입력을 계산한다  (feedback(K, G))
%      3) 구동기 한계와 비교한다
%      4) 넘으면 K 를 줄이거나 더 큰 구동기를 쓴다
%      5) 줄인 K 로 사양을 다시 확인한다

%% 5. 포화를 견디는 이득 찾기
%
%  구동기가 24 V 라고 합시다.
%  포화가 걸리지 않으면서 사양도 만족하는 K 가 있을까요?

u_avail = 24;
fprintf('=== 구동기 %.0f V 로 쓸 수 있는 이득 ===\n', u_avail);
fprintf('     K   필요 최대입력[V]  포화?  오버슈트[%%]  정착시간[s]\n');
fprintf('  -----  ----------------  -----  ----------  -----------\n');
for Kx = [5 10 20 30 50]
    u_need = max(abs(step(r_amp*feedback(Kx, G), t)));
    ii = stepinfo(feedback(Kx*G,1));
    if u_need > u_avail, sat = '예'; else, sat = '아니오'; end
    fprintf('  %5.0f  %16.1f  %5s  %10.1f  %11.2f\n', ...
            Kx, u_need, sat, ii.Overshoot, ii.SettlingTime);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    이득이 클수록 필요한 전압이 커집니다. u = K*e 이니 당연합니다.\n');
fprintf('    목표 각도 1 rad 에 대해 초기 오차가 1 rad 이므로\n');
fprintf('    초기 제어입력은 거의 K 그 자체입니다.\n');
fprintf('    즉 이 시스템에서는 K 가 곧 필요 전압이라고 봐도 됩니다.\n\n');

%% 6. 직접 해 볼 것
%
%   (1) 목표 각도 r_amp 를 0.5 로 줄이면 필요한 전압은?
%       -> 절반이 된다. 즉 작은 동작에서는 큰 이득을 써도 된다.
%          이것이 실무에서 이득을 동작 크기에 따라 바꾸는 이유다 (게인 스케줄링)
%
%   (2) u_lim = 5 로 아주 작게 하면?
%       -> 거의 항상 포화되어 응답이 매우 느려진다.
%          제어기가 사실상 일을 못 하는 상태다.
%
%   (3) 모델에서 포화 블록을 지우고 선을 이으면?
%       -> u_lim 을 아무리 바꿔도 결과가 변하지 않는다.
%
%   (4) K 를 130 (임계이득 위)으로 두고 u_lim = 1e6 으로 실행하면?
%       -> 발산한다. 5주차에서 배운 그대로다.
%          그런데 u_lim = 24 로 하면? 포화 때문에 발산이 억제되어
%          일정한 크기로 진동한다. 이것을 리밋 사이클이라 한다.
%          비선형 요소가 만드는 현상으로, 선형 이론으로는 설명할 수 없다.
%
%  모델 열기:
%      >> open_system('W06_Rlocus_Verify')
