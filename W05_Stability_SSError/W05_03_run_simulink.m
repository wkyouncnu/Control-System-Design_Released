%% W05_03_run_simulink.m
%  5주차 실습 (3) : 적분기를 켜고 끄며 오차가 사라지는 것 보기
%
%  모델 W05_SteadyStateError.slx 는 DC 모터 속도제어에 PI 제어기를 붙인 것입니다.
%
%      u = Kp*e + Ki*(e 의 적분)
%
%  Ki 하나로 적분기를 켜고 끌 수 있습니다.
%      Ki = 0 : 순수 비례제어  -> 정상상태 오차가 남음
%      Ki > 0 : 적분기 동작    -> 오차가 0 으로 감
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W05_SteadyStateError')
%  열고 Ctrl+T 를 누르면 Scope 두 개가 열립니다. 기본값은 Ki = 0 입니다.
%
%  제어시스템설계 5주차 | 충남대학교 자율운항시스템공학과

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

model = 'W05_SteadyStateError';

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

%% 1. 파라미터
[G, p] = plant_dcmotor('speed');
[numG, denG] = tfdata(G, 'v');       %#ok<ASGLU>  <- 모델의 Transfer Fcn 이 사용

r_amp = 10;      % 목표 각속도 [rad/s]
t_end = 5;
Kp    = 50;

t = (0:0.002:t_end)';

fprintf('=== 플랜트 ===\n');
G
fprintf('DC 이득 G(0) = %.4f\n', dcgain(G));
fprintf('비례이득 Kp = %d 일 때\n', Kp);
fprintf('  루프이득 Kp*G(0) = %.3f\n', Kp*dcgain(G));
fprintf('  이론 정상상태 오차 = r/(1+Kp*G(0)) = %.4f rad/s\n\n', ...
        r_amp/(1+Kp*dcgain(G)));

%% 2. Ki 를 바꿔 가며 실행
%
%  Ki 를 0, 2, 5 로 바꿔 가며 돌립니다.
%  Ki = 0 이면 적분 경로가 꺼진 것과 같습니다.

%  Ki 를 얼마로 잡을지
%    너무 작으면 적분이 느려 시뮬레이션 시간 안에 오차가 안 사라집니다.
%    너무 크면 불안정해집니다 (4절에서 한계를 계산합니다).
%    이 플랜트에서는 한계가 720 정도이므로 그 아래에서 넉넉히 잡습니다.
Ki_list = [0 100 300];

figure('Name','적분기의 효과');
tiledlayout(2,1,'TileSpacing','compact');

fprintf('=== Ki 를 바꿔 가며 ===\n');
fprintf('    Ki   최종 각속도   정상상태 오차   설명\n');
fprintf('  -----  -----------  -------------  ----------------\n');

Y = zeros(numel(t), numel(Ki_list));
E = zeros(numel(t), numel(Ki_list));
for i = 1:numel(Ki_list)
    Ki = Ki_list(i);                 %#ok<NASGU>  <- 모델이 이 값을 읽습니다
    out = sim(model);
    Y(:,i) = interp1(out.y_sim.Time, squeeze(out.y_sim.Data), t);
    E(:,i) = interp1(out.e_sim.Time, squeeze(out.e_sim.Data), t);

    err_end = r_amp - Y(end,i);
    if Ki_list(i) == 0
        note = '비례제어만 -> 오차가 남는다';
    elseif abs(err_end) < 0.01
        note = '적분기 동작 -> 오차가 사라졌다';
    else
        note = '적분이 아직 진행 중';
    end
    fprintf('  %5.0f  %11.4f  %13.4f  %s\n', ...
            Ki_list(i), Y(end,i), err_end, note);
end
fprintf('\n');

nexttile
for i = 1:numel(Ki_list)
    plot(t, Y(:,i), 'LineWidth', 2); hold on;
end
yline(r_amp, 'k--', 'LineWidth', 1.5); grid on;
ylabel('각속도 [rad/s]');
title('적분기를 켜면 오차가 사라진다');
legend([arrayfun(@(k) sprintf('K_i = %.0f', k), Ki_list, 'UniformOutput', false), ...
        {'목표값'}], 'Location','southeast');

nexttile
for i = 1:numel(Ki_list)
    plot(t, E(:,i), 'LineWidth', 2); hold on;
end
yline(0, 'k--', 'LineWidth', 1.5); grid on;
xlabel('시간 [s]'); ylabel('오차 e [rad/s]');
title('오차 신호');

%% 3. MATLAB 계산과 대조
%
%  같은 것을 전달함수로도 계산해 확인합니다.
%  PI 제어기의 전달함수는 이렇습니다.
%
%      C(s) = Kp + Ki/s = (Kp*s + Ki)/s

fprintf('=== MATLAB 계산과 대조 ===\n');
for i = 1:numel(Ki_list)
    C = Kp + Ki_list(i)/s;
    T = feedback(C*G, 1);
    ym = lsim(T, r_amp*ones(size(t)), t);
    fprintf('  Ki = %3.0f : 최대 차이 %.2e  (목표값 대비 %.4f %%)\n', ...
            Ki_list(i), max(abs(Y(:,i) - ym)), 100*max(abs(Y(:,i) - ym))/r_amp);
end
fprintf('  --> 목표값의 0.1 %% 아래입니다. 같은 시스템으로 봅니다.\n');
fprintf('      완전히 0 이 아닌 것은 Simulink 가 수치적분을 하기 때문입니다.\n\n');

%% 4. 적분기를 너무 키우면
%
%  Ki 를 계속 키우면 어떻게 될까요?
%  W05_02 에서 배운 대로 불안정해집니다.
%
%  PI 제어를 붙인 폐루프 특성방정식은 이렇습니다.
%
%      s*(0.005*s^2 + 0.06*s + 0.1001) + 0.01*(Kp*s + Ki) = 0
%      0.005*s^3 + 0.06*s^2 + (0.1001 + 0.01*Kp)*s + 0.01*Ki = 0
%
%  3차 안정 조건 a2*a1 > a3*a0 을 쓰면
%
%      0.06*(0.1001 + 0.01*Kp) > 0.005*0.01*Ki
%
%  이것을 Ki 에 대해 풀면 상한이 나옵니다.

a3 = denG(1); a2 = denG(2); a1c = denG(3) + numG(end)*Kp;
Ki_max = (a2*a1c)/(a3*numG(end));

fprintf('=== Ki 의 상한 ===\n');
fprintf('  손 계산 : Ki < %.2f  (Kp = %d 일 때)\n', Ki_max, Kp);

% 수치로 확인
Ki_scan = linspace(0.1, Ki_max*1.5, 800);
mx = zeros(size(Ki_scan));
for i = 1:numel(Ki_scan)
    C = Kp + Ki_scan(i)/s;
    mx(i) = max(real(pole(feedback(C*G,1))));
end
idx = find(mx > 0, 1);
fprintf('  수치 확인 : Ki_crit = %.2f\n', Ki_scan(idx));
fprintf('  --> 일치합니다.\n\n');

figure('Name','Ki 의 상한');
plot(Ki_scan, mx, 'LineWidth', 2); hold on;
yline(0, 'r--', 'LineWidth', 2);
xline(Ki_max, 'k:', 'LineWidth', 2);
grid on; xlabel('적분이득 K_i'); ylabel('폐루프 극점의 최대 실수부');
title(sprintf('K_i 를 키우면 불안정해진다 (한계 %.1f)', Ki_max));
legend('최대 실수부','안정 경계','손 계산 한계','Location','northwest');

%% 4-1. 상한을 넘겨 보기
%
%  Ki 를 한계 위로 올려 실제로 발산하는지 확인합니다.

Ki = Ki_max*1.2;                     %#ok<NASGU>
out_bad = sim(model);
y_bad = interp1(out_bad.y_sim.Time, squeeze(out_bad.y_sim.Data), t);

figure('Name','Ki 가 너무 크면');
plot(t, Y(:,3), 'LineWidth', 2); hold on;
plot(t, y_bad, 'LineWidth', 2);
yline(r_amp, 'k--', 'LineWidth', 1.5); grid on;
xlabel('시간 [s]'); ylabel('각속도 [rad/s]');
title('적분이득이 한계를 넘으면 발산한다');
legend(sprintf('K_i = %.0f (안정)', Ki_list(3)), ...
       sprintf('K_i = %.1f (불안정)', Ki_max*1.2), '목표값', 'Location','northwest');

fprintf('=== 상한을 넘기면 ===\n');
fprintf('  Ki = %.1f (한계의 1.2 배) 일 때 최종값 %.1f rad/s -> 발산\n', ...
        Ki_max*1.2, y_bad(end));
fprintf('  --> 적분기는 오차를 없애 주지만 공짜가 아닙니다.\n\n');

%% 5. 직접 해 볼 것
%
%   (1) Kp 를 100 으로 올리면 Ki 의 상한은 어떻게 되는가?
%       -> 손 계산 공식으로 예측하고 확인하라
%
%   (2) 목표값 r_amp 를 20 으로 바꾸면 정상상태 오차는?
%       -> 비례제어(Ki=0)에서는 오차도 2 배가 된다. 왜 그런가?
%
%   (3) 모델에서 적분기 블록을 지우고 선을 이으면?
%       -> Ki 를 아무리 키워도 오차가 사라지지 않는다.
%          적분기가 하는 일이 무엇인지 확인하는 실험
%
%   (4) 적분기의 초기조건을 5 로 주면 어떻게 되는가?
%       -> 처음부터 제어입력이 나와 시작이 다르다.
%          이것이 11주차에서 배울 적분기 와인드업 문제의 씨앗이다
%
%  모델 열기:
%      >> open_system('W05_SteadyStateError')
