%% W13_03_pendulum_balance.m
%  13주차 실습 (3) : 거꾸로 선 진자를 세운다 — 학기의 하이라이트
%
%  3주차에서 이 진자를 처음 만났습니다. 거꾸로 세우면 고유값 하나가
%  +5.72 가 되어 **손을 떼면 넘어간다**는 것을 봤습니다.
%
%  12주차에서 가제어임을 확인했습니다. 그러니 세울 수 있습니다.
%  오늘 실제로 세웁니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 불안정한 극점을 좌반면으로 옮길 수 있는가?  -> 2절
%    Q2. 얼마나 빨리 세울 것인가?                    -> 3절
%    Q3. 선형 설계가 진짜 진자에서도 통하는가?       -> 4절
%    Q4. 얼마나 크게 기울어져도 세울 수 있는가?      -> 5절
%
%  돌리면 나오는 것
%    표 3개 + 그림 4장 (극점 이동, 응답, 비선형 검증, 유효범위)
%    걸리는 시간 : 약 10 초
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

%% 1. 플랜트 — 거꾸로 선 진자
%
%  3주차의 그 진자를 theta0 = 180도 에서 선형화한 것입니다.
%  상태는 둘, 입력은 축에 거는 토크 하나입니다.
%
%    x1 = 기울어진 각도 (직립에서 잰 것),  x2 = 각속도

[sysUp, pUp] = plant_pendulum(pi);
A = pUp.A;  B = pUp.B;  C = pUp.C;  D = pUp.D;

fprintf('=== 1. 거꾸로 선 진자 ===\n');
fprintf('  A = %s\n', mat2str(round(A, 4)));
fprintf('  B = %s\n', mat2str(round(B, 4)));
fprintf('  개루프 고유값 : %s\n', mat2str(round(eig(A).', 4)));
fprintf('  --> +%.2f 가 있습니다. **손을 떼면 넘어갑니다.**\n', max(real(eig(A))));
fprintf('      그 모드의 시정수는 %.3f 초입니다.\n', 1/max(real(eig(A))));
fprintf('      즉 %.0f ms 마다 기울기가 e 배씩 커집니다.\n\n', 1000/max(real(eig(A))));

fprintf('  rank(ctrb) = %d / 2  ->  가제어. 세울 수 있습니다\n\n', rank(ctrb(A,B)));

%% 2. 극배치로 세운다
%
%  개루프 극점 +5.72 와 -5.72 를 둘 다 좌반면으로 옮깁니다.
%
%  어디에 놓을 것인가 — 4주차의 사양 공식을 그대로 씁니다.
%  오버슈트 10 % 이하, 정착시간 1 초 이하로 잡아 봅시다.

[zeta_min, wn_min, s_t] = spec2pole(10, 1);
p_des = [s_t, conj(s_t)];

K = place(A, B, p_des);
Acl = A - B*K;

fprintf('=== 2. 극배치 ===\n');
fprintf('  사양 : 오버슈트 10 %% 이하, 정착시간 1 s 이하\n');
fprintf('  spec2pole -> zeta >= %.4f, wn >= %.4f\n', zeta_min, wn_min);
fprintf('  목표 극점 : %.3f +- %.3fj\n', real(s_t), imag(s_t));
fprintf('  K = %s\n', mat2str(round(K, 4)));
fprintf('  검증 eig(A-BK) = %s\n', mat2str(round(eig(Acl).', 4)));
fprintf('  --> 우반면 극점이 사라졌습니다. **세워졌습니다.**\n\n');

figure('Name', '거꾸로 선 진자를 세운다');
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
plot(real(eig(A)), imag(eig(A)), 'x', 'MarkerSize', 17, 'LineWidth', 3.4, ...
     'Color', [0.85 0.20 0.15]); hold on; grid on;
plot(real(eig(Acl)), imag(eig(Acl)), 'o', 'MarkerSize', 13, 'LineWidth', 3, ...
     'Color', [0.00 0.45 0.74]);
xline(0, 'k-', 'LineWidth', 2);
yline(0, 'k:');
xlim([-9 9]); ylim([-6 6]);
xlabel('실수부'); ylabel('허수부');
legend('개루프 (하나가 우반면)', '상태궤환 후', 'Location', 'northwest');
title('우반면 극점을 좌반면으로 끌어왔다');

nexttile
t = (0:0.002:2)';
x0 = [deg2rad(10); 0];                     % 10도 기울인 채로 시작
y_open   = initial(ss(A,   B, C, 0), x0, t);
y_closed = initial(ss(Acl, B, C, 0), x0, t);
plot(t, rad2deg(y_open), 'LineWidth', 2.4, 'Color', [0.85 0.20 0.15]); hold on; grid on;
plot(t, rad2deg(y_closed), 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74]);
yline(0, 'k--', 'LineWidth', 1.4);
xlabel('시간 [s]'); ylabel('기울어진 각도 [도]');
ylim([-15 60]);
legend('제어 없음 (넘어간다)', '상태궤환 (돌아온다)', 'Location', 'northwest');
title('10도 기울인 채로 놓았을 때');

fprintf('  10도 기울여 놓았을 때\n');
fprintf('    제어 없음   : 2 초 뒤 %.0f 도 (넘어갔다)\n', rad2deg(y_open(end)));
fprintf('    상태궤환    : 2 초 뒤 %.3f 도 (돌아왔다)\n\n', rad2deg(y_closed(end)));

%% 3. 얼마나 빨리 세울 것인가 — 대가
%
%  극을 더 왼쪽으로 보내면 더 빨리 세워집니다.
%  그런데 필요한 **토크**가 커집니다.

fprintf('=== 3. 빨리 세울수록 토크가 커진다 ===\n');
fprintf('     정착시간 목표[s]   목표 극점        |K|      최대 토크[Nm]\n');
fprintf('   ----------------  --------------  --------  --------------\n');

ts_list = [2.0 1.5 1.0 0.7 0.5];
UM = zeros(size(ts_list));  TSr = zeros(size(ts_list));
t3 = (0:0.001:3)';
for i = 1:numel(ts_list)
    [~, ~, st] = spec2pole(10, ts_list(i));
    Ki = place(A, B, [st, conj(st)]);
    Ai = A - B*Ki;
    [~, ~, Xi] = lsim(ss(Ai, B, eye(2), [0;0]), zeros(size(t3)), t3, x0);
    ui = -(Ki*Xi.').';
    UM(i)  = max(abs(ui));
    si = stepinfo(rad2deg(initial(ss(Ai,B,C,0), x0, t3)), t3, 0);
    TSr(i) = si.SettlingTime;
    fprintf('   %16.1f  %6.2f+-%5.2fj  %8.1f  %14.2f\n', ...
            ts_list(i), real(st), imag(st), norm(Ki), UM(i));
end
fprintf('\n');

figure('Name', '빨리 세울수록 토크가 커진다');
semilogy(ts_list, UM, 'o-', 'LineWidth', 2.4, 'MarkerSize', 9, ...
         'Color', [0.85 0.20 0.15]); grid on;
set(gca, 'XDir', 'reverse');
xlabel('정착시간 목표 [s]  (왼쪽이 더 빠름)');
ylabel('최대 토크 [Nm]  (로그 눈금)');
title('10도에서 세울 때 필요한 토크');

fprintf('  정착시간을 %.1f s 에서 %.1f s 로 줄이면\n', ts_list(1), ts_list(end));
fprintf('    필요한 토크가 %.2f -> %.2f Nm 로 %.1f 배 커집니다.\n', ...
        UM(1), UM(end), UM(end)/UM(1));
fprintf('  --> 모터가 낼 수 있는 토크가 상한을 정합니다.\n\n');

%% 4. 선형 설계가 진짜 진자에서도 통하는가
%
%  **가장 중요한 절입니다.**
%
%  우리가 설계한 K 는 **선형 모델**을 보고 만든 것입니다.
%  진짜 진자는 비선형입니다 (sin 이 들어 있습니다).
%
%  3주차의 마지막 교훈이 여기서 적용됩니다 —
%  **설계한 제어기를 다시 비선형 모델에 붙여서 검증한다.**

%  [좌표 주의 — 여기서 반드시 짚고 갑니다]
%    plant_pendulum 의 비선형 함수 p.f 는 **매달린 자세(theta = 0)** 를
%    기준으로 절대 각도를 받습니다.
%    반면 선형 모델 (A, B) 는 **직립(theta = pi)** 기준의 **편차**입니다.
%
%    그래서 비선형 시뮬레이션에 제어기를 붙일 때는 좌표를 맞춰야 합니다.
%
%      편차   dx = [theta - pi ; theta_dot]
%      제어입력 u = u0 + (-K*dx),   u0 = m*g*l*sin(pi) = 0
%
%    이것을 빼먹으면 "직립에서 10도" 를 "매달린 데서 10도" 로 잘못 넣게 되어
%    아무 제어기나 다 성공하는 것처럼 보입니다. **반드시 확인하십시오.**

dev   = @(x) [x(1) - pi; x(2)];                    % 절대 -> 직립 기준 편차
f_nl  = @(t, x, Kc) pUp.f(x, pUp.u0 - Kc*dev(x));  % 비선형 진자 + 상태궤환
abs0  = @(deg) [pi + deg2rad(deg); 0];             % 직립에서 deg 만큼 기울인 절대 상태

t4 = [0 2];
figure('Name', '비선형 검증');
tiledlayout(1, 2, 'TileSpacing', 'compact');

tl = (0:0.002:2)';
fprintf('=== 4. 비선형 검증 ===\n');
for k = 1:2
    if k == 1, d0 = 10; else, d0 = 40; end
    [tn, xn] = ode45(@(t,x) f_nl(t, x, K), t4, abs0(d0));
    yl = initial(ss(Acl, B, C, 0), [deg2rad(d0); 0], tl);

    nexttile
    hold on; grid on;
    plot(tn, rad2deg(xn(:,1) - pi), 'LineWidth', 3, 'Color', [0.85 0.20 0.15]);
    plot(tl, rad2deg(yl), '--', 'LineWidth', 2.2, 'Color', [0.00 0.45 0.74]);
    yline(0, 'k:');
    xlabel('시간 [s]'); ylabel('직립에서 기울어진 각도 [도]');
    legend('비선형 진자 (진짜)', '선형 모델 (설계할 때 본 것)', 'Location','northeast');
    title(sprintf('%d도에서 놓았을 때', d0));

    fprintf('  %2d도 : 비선형 최저점 %.2f 도, 선형 최저점 %.2f 도\n', ...
            d0, min(rad2deg(xn(:,1) - pi)), min(rad2deg(yl)));
end
fprintf('  --> 작은 각에서는 거의 겹치고, 큰 각에서는 **가는 길이 달라집니다.**\n');
fprintf('      3주차에서 배운 선형화의 유효범위 문제 그대로입니다.\n\n');

%% 5. 진짜 한계는 토크다 — 구동기 포화
%
%  4절에서 40도까지도 세워졌습니다. 그런데 그건 **토크를 무한히 낼 수
%  있다고 가정**했기 때문입니다.
%
%  실제 모터는 정해진 토크까지만 냅니다. 3절 표에서 이 설계는
%  10도에서 0.62 Nm 를 요구했습니다. 그럼 더 크게 기울면?
%
%  토크 한계를 넣고 다시 훑어 봅니다. **여기가 오늘의 마지막 교훈입니다.**

tau_lim = [Inf 1.0 0.6];
deg_list = 5:5:70;
OK = false(numel(tau_lim), numel(deg_list));

for j = 1:numel(tau_lim)
    lim_j = tau_lim(j);
    f_sat = @(t, x) pUp.f(x, max(min(pUp.u0 - K*dev(x), lim_j), -lim_j));
    for i = 1:numel(deg_list)
        [~, xi] = ode45(f_sat, [0 6], abs0(deg_list(i)));
        OK(j,i) = abs(rad2deg(xi(end,1) - pi)) < 1;
    end
end

fprintf('=== 5. 토크 한계를 넣으면 ===\n');
fprintf('   초기 각도[도]  ');
for j = 1:numel(tau_lim)
    if isinf(tau_lim(j)), fprintf('  한계없음'); else, fprintf('  %.1f Nm', tau_lim(j)); end
end
fprintf('\n   -------------  --------  --------  --------\n');
for i = 1:numel(deg_list)
    fprintf('   %13d  ', deg_list(i));
    for j = 1:numel(tau_lim)
        if OK(j,i), fprintf('%8s', '세움'); else, fprintf('%8s', '넘어짐'); end
    end
    fprintf('\n');
end
fprintf('\n');

for j = 1:numel(tau_lim)
    k = find(OK(j,:), 1, 'last');
    if isempty(k), lm = 0; else, lm = deg_list(k); end
    if isinf(tau_lim(j))
        fprintf('  토크 한계 없음 : %d 도까지 세운다\n', lm);
    else
        fprintf('  토크 한계 %.1f Nm : %d 도까지만 세운다\n', tau_lim(j), lm);
    end
end
fprintf('\n');
fprintf('  --> **유효범위를 정하는 것은 선형화가 아니라 토크입니다.**\n');
fprintf('      토크가 모자라면 넘어가는 것을 지켜볼 수밖에 없습니다.\n');
fprintf('      10강 slide 106~108 의 control saturation 이 이 이야기입니다.\n\n');

figure('Name', '토크 한계와 유효범위');
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
imagesc(deg_list, 1:numel(tau_lim), double(OK));
colormap([0.92 0.80 0.78; 0.80 0.92 0.80]);
set(gca, 'YTick', 1:numel(tau_lim), 'YTickLabel', ...
    {'한계 없음', '1.0 Nm', '0.6 Nm'});
xlabel('초기 기울기 [도]');
title('초록 = 세움, 분홍 = 넘어짐');

nexttile
hold on; grid on;
d0 = 35;
col = [0.20 0.20 0.20; 0.00 0.45 0.74; 0.85 0.20 0.15];
for j = 1:numel(tau_lim)
    lim_j = tau_lim(j);
    f_sat = @(t, x) pUp.f(x, max(min(pUp.u0 - K*dev(x), lim_j), -lim_j));
    [tj, xj] = ode45(f_sat, [0 4], abs0(d0));
    if isinf(lim_j), nm = '한계 없음'; else, nm = sprintf('%.1f Nm', lim_j); end
    plot(tj, rad2deg(xj(:,1) - pi), 'LineWidth', 2.4, 'Color', col(j,:), ...
         'DisplayName', nm);
end
yline(0, 'k--', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('직립에서 기울어진 각도 [도]');
ylim([-90 200]);
legend('Location', 'northwest');
title(sprintf('%d 도에서 놓았을 때', d0));

%% 6. 이번 실습의 정리
%
%  - 개루프 불안정 극점 +5.72 를 좌반면으로 옮겨 **진자를 세웠다**
%  - 조건은 가제어. 12주차에서 확인해 두었다
%  - 극을 왼쪽으로 보낼수록 빨라지지만 **토크가 급증한다**
%  - 선형 설계를 **반드시 비선형 모델로 검증**해야 한다 (3주차의 교훈)
%  - 유효범위를 정하는 것은 선형화가 아니라 **구동기 토크**다
%
%  다음 실습 : W13_04_run_simulink.m 에서 포화가 있는 실제 상황을 봅니다.

fprintf('=== 정리 ===\n');
fprintf('  세울 수 있다. 다만 토크와 유효범위라는 두 한계가 있다\n');
fprintf('  그런데 이 설계에는 **아직 큰 가정이 하나** 있습니다.\n');
fprintf('  u = -K*x 를 쓰려면 x 를 **전부 알아야** 합니다.\n');
fprintf('  각속도를 못 재면 어떻게 할까요? --> 14주차의 관측기\n');
