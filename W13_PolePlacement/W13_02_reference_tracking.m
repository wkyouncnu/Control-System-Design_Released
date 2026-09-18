%% W13_02_reference_tracking.m
%  13주차 실습 (2) : 지령 추종 — 극배치만으로는 부족하다
%
%  이 스크립트에서 답할 질문
%    Q1. 극배치를 했는데 왜 목표에 안 가는가?    -> 1절
%    Q2. Kr 은 어떻게 구하는가?                  -> 2절
%    Q3. Kr 은 모델이 틀리면 어떻게 되는가?      -> 3절
%    Q4. 그럼 무엇을 써야 하는가?                -> 4절
%    Q5. 상태궤환은 결국 무엇과 비슷한가?        -> 5절
%
%  돌리면 나오는 것
%    표 3개 + 그림 3장
%    걸리는 시간 : 약 5 초
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
s = tf('s');

[Gp, p] = plant_dcmotor('position');
sys = ss(p.A, p.B, p.C, p.D);
p_des = [-8 -10 -12];
K = place(p.A, p.B, p_des);
Acl = p.A - p.B*K;
t = (0:0.005:1.5)';

%% 1. 극배치를 했는데 목표에 안 간다
%
%  극배치는 A 를 A - B*K 로 바꿔 **고유값만** 옮깁니다.
%  직류이득은 아무도 신경 쓰지 않았습니다.
%
%  그래서 지령 r 을 그대로 넣으면 (u = -Kx + r) 엉뚱한 값에 수렴합니다.

sys_cl1 = ss(Acl, p.B, p.C, p.D);            % Kr = 1
dc1 = dcgain(sys_cl1);

fprintf('=== 1. 극배치만 하면 ===\n');
fprintf('  폐루프 고유값 : %s   <- 원하는 자리에 잘 갔다\n', ...
        mat2str(round(sort(eig(Acl)).', 4)));
fprintf('  그런데 직류이득 = %.6f\n', dc1);
fprintf('  --> 목표가 1 인데 %.4f 에 수렴합니다. 오차 %.1f %% 입니다.\n\n', ...
        dc1, abs(1-dc1)*100);

fprintf('  왜 이런가\n');
fprintf('    극배치는 "얼마나 빨리, 얼마나 흔들리며" 만 정합니다.\n');
fprintf('    "어디에 멈출 것인가" 는 정하지 않습니다.\n');
fprintf('    그것은 직류이득이 정하는데, 우리가 안 건드렸습니다.\n\n');

%% 2. Kr — 앞단에 상수 하나
%
%  해법은 단순합니다. 지령에 상수 하나를 곱해 줍니다.
%
%      u = -K x + Kr * r
%
%  직류이득이 1 이 되게 하려면
%
%      Kr = 1 / dcgain(A - B*K, B, C, D)
%         = 1 / ( C * inv(-(A - B*K)) * B )
%
%  유도는 두 줄입니다. 정상상태에서는 x' = 0 이므로
%
%      0 = (A - B*K) x_ss + B*Kr*r     ->    x_ss = -inv(A-BK) * B * Kr * r
%      y_ss = C x_ss = -C inv(A-BK) B Kr r
%
%  이것이 r 과 같아지려면 Kr 이 위 값이어야 합니다.

Kr = 1/dcgain(sys_cl1);
sys_cl2 = ss(Acl, p.B*Kr, p.C, p.D);

fprintf('=== 2. Kr 보정 ===\n');
fprintf('  Kr = 1 / %.6f = %.4f\n', dc1, Kr);
fprintf('  보정 후 직류이득 = %.6f\n\n', dcgain(sys_cl2));

y1 = step(sys_cl1, t);
y2 = step(sys_cl2, t);

figure('Name', 'Kr 보정');
plot(t, y1, 'LineWidth', 2.4); hold on; grid on;
plot(t, y2, 'LineWidth', 2.4);
yline(1, 'k--', 'LineWidth', 1.5);
xlabel('시간 [s]'); ylabel('각도 [rad]');
legend(sprintf('K_r = 1 (그냥 넣으면) : %.4f 에서 멈춤', y1(end)), ...
       sprintf('K_r = %.1f (보정하면) : %.4f', Kr, y2(end)), ...
       '목표 1', 'Location', 'east');
title('극배치는 극점만 옮긴다. 직류이득은 따로 맞춰야 한다');

fprintf('  두 응답의 **모양은 완전히 같습니다.** 크기만 다릅니다.\n');
fprintf('  고유값이 같으니 당연합니다. Kr 은 세로 배율일 뿐입니다.\n\n');

%% 3. Kr 의 약점 — 모델이 틀리면
%
%  Kr 은 **모델을 믿고 미리 계산한 값**입니다.
%  1주차와 5주차에서 본 그 문제가 그대로 돌아옵니다.
%
%  그런데 **놀라운 일이 하나 있습니다.** 지금 쓰는 위치 모델에서는
%  모델을 아무리 틀리게 해도 오차가 안 생깁니다. 먼저 확인해 봅시다.

fprintf('=== 3. 모델이 틀리면 ===\n');
fprintf('  (a) 위치 모델 — 파라미터를 30 %% 씩 틀려 본다\n');
fprintf('      %-24s  정상상태   오차[%%]\n', '무엇이 틀렸나');
fprintf('      %-24s  --------   -------\n', '------------');
pert = {'기계 마찰 A(2,2)', 2, 2; '전기 저항 A(3,3)', 3, 3; '역기전력 A(3,2)', 3, 2};
for k = 1:3
    A_r = p.A;  A_r(pert{k,2}, pert{k,3}) = A_r(pert{k,2}, pert{k,3})*1.3;
    g = dcgain(ss(A_r - p.B*K, p.B*Kr, p.C, p.D));
    fprintf('      %-24s  %8.4f   %7.2f\n', pert{k,1}, g, abs(1-g)*100);
end
A_r = p.A;  B_r = p.B*0.8;
g = dcgain(ss(A_r - B_r*K, B_r*Kr, p.C, p.D));
fprintf('      %-24s  %8.4f   %7.2f\n\n', '토크상수 B 가 20 % 작음', g, abs(1-g)*100);

fprintf('  왜 오차가 안 생기는가 — **플랜트 안에 적분기가 있기 때문**입니다.\n');
fprintf('    A 의 첫 열이 전부 0 입니다. 각도는 각속도의 적분일 뿐이라\n');
fprintf('    각도 자신은 방정식에 안 나옵니다.\n');
fprintf('    그러면 각도 되먹임 k1 이 **적분기를 감싼 비례루프**가 되어\n');
fprintf('    5주차의 타입 1 처럼 계단 오차가 저절로 0 이 됩니다.\n\n');

%% 3-1. 적분기가 없는 플랜트에서는 — 속도 모델
%
%  같은 실험을 **속도 모델**로 하면 이야기가 달라집니다.
%  속도 모델은 타입 0 입니다. 안에 적분기가 없습니다.

[Gsp, ps] = plant_dcmotor('speed');
Ks  = place(ps.A, ps.B, [-8 -12]);
Krs = 1/dcgain(ss(ps.A - ps.B*Ks, ps.B, ps.C, ps.D));
ts  = (0:0.005:1.2)';

fprintf('  (b) 속도 모델 — 토크상수가 틀린 경우\n');
fprintf('      K = %s,  Kr = %.2f\n', mat2str(round(Ks,3)), Krs);
fprintf('      %-16s  정상상태   오차[%%]\n', '토크상수');
fprintf('      %-16s  --------   -------\n', '--------');
fac = [0.8 1.0 1.3];
Yv = zeros(numel(ts), numel(fac));
for k = 1:numel(fac)
    B_r = ps.B*fac(k);
    S = ss(ps.A - B_r*Ks, B_r*Krs, ps.C, ps.D);
    Yv(:,k) = step(S, ts);
    fprintf('      %-16.1f  %8.4f   %7.2f\n', fac(k), dcgain(S), ...
            abs(1-dcgain(S))*100);
end
fprintf('\n');

figure('Name', 'Kr 은 모델을 믿는다');
hold on; grid on;
for k = 1:numel(fac)
    plot(ts, Yv(:,k), 'LineWidth', 2.4, ...
         'DisplayName', sprintf('토크상수 \\times %.1f  (%.4f)', fac(k), Yv(end,k)));
end
yline(1, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('각속도 [rad/s]');
legend('Location', 'southeast');
title('적분기가 없는 플랜트에서는 K_r 이 모델 오차에 그대로 흔들린다');

fprintf('  Kr 은 **오차를 보지 않습니다.** 그래서 스스로 고칠 수 없습니다.\n');
fprintf('  5주차의 "Kr 대 적분기" 논의와 정확히 같은 이야기입니다.\n\n');

fprintf('  실무 규칙\n');
fprintf('    플랜트 안에 적분기가 있으면 Kr 만으로도 계단 오차가 0 이 된다\n');
fprintf('    없으면 Kr 은 모델 오차만큼 어긋난다\n');
fprintf('    그래서 **어느 쪽인지 먼저 확인**하고 4절로 갈지 정하십시오\n\n');

% 뒤 절에서 쓸 "모델이 틀린 위치 모델" (여기서는 B 를 20 % 줄인다)
A_real = p.A;
B_real = p.B*0.8;
y3 = step(ss(A_real - B_real*K, B_real*Kr, p.C, p.D), t);

%% 4. 그럼 무엇을 써야 하는가 — 적분 상태를 하나 더
%
%  정상상태 오차를 확실히 없애려면 **적분기**를 넣어야 합니다.
%  상태공간에서는 상태를 하나 늘리는 것으로 합니다.
%
%      xi' = r - y            <- 오차의 적분을 새 상태로
%
%  확대 시스템은 이렇게 됩니다.
%
%      [x ]'   [ A    0 ] [x ]   [B]        [0]
%      [xi]  = [-C    0 ] [xi] + [0] u  +   [1] r
%
%  여기에 극배치를 하면 상태가 n+1 개인 제어기가 나옵니다.
%  이것을 **적분 상태궤환** 또는 서보 문제라고 부릅니다.

%  3-1 절에서 문제가 드러난 **속도 모델**로 해 봅니다.

ns = size(ps.A, 1);
Aa = [ps.A, zeros(ns,1); -ps.C, 0];
Ba = [ps.B; 0];
Brr = [zeros(ns,1); 1];

fprintf('=== 4. 적분 상태를 하나 더 (속도 모델) ===\n');
fprintf('  확대 시스템 : 상태 %d 개 (원래 %d 개 + 적분 1 개)\n', size(Aa,1), ns);
fprintf('  rank(ctrb) = %d / %d  ->  %s\n', rank(ctrb(Aa, Ba)), size(Aa,1), ...
        string(rank(ctrb(Aa,Ba)) == size(Aa,1)).replace("true","가제어"). ...
        replace("false","가제어 아님"));

p_aug = [-8 -12 -15];
Ka = place(Aa, Ba, p_aug);
Kx = Ka(1:ns);  Ki = Ka(end);
fprintf('  극점을 %s 에 놓으면\n', mat2str(p_aug));
fprintf('    Kx = %s,  Ki = %.2f\n\n', mat2str(round(Kx,3)), Ki);

t2 = (0:0.005:2.0)';
fprintf('  %-16s  K_r 보정   적분 상태궤환\n', '토크상수');
fprintf('  %-16s  --------   ------------\n', '--------');
Ya = zeros(numel(t2), numel(fac));
for k = 1:numel(fac)
    B_r  = ps.B*fac(k);
    Sa   = ss([ps.A, zeros(ns,1); -ps.C, 0] - [B_r;0]*Ka, Brr, [ps.C 0], 0);
    Ya(:,k) = step(Sa, t2);
    S_kr = ss(ps.A - B_r*Ks, B_r*Krs, ps.C, ps.D);
    fprintf('  %-16.1f  %8.4f   %12.6f\n', fac(k), dcgain(S_kr), dcgain(Sa));
end
fprintf('\n');
fprintf('  --> **적분 상태궤환은 모델이 틀려도 오차를 0 으로 만듭니다.**\n\n');

figure('Name', '적분 상태궤환');
hold on; grid on;
for k = 1:numel(fac)
    plot(t2, Ya(:,k), 'LineWidth', 2.4, ...
         'DisplayName', sprintf('적분 상태궤환, 토크상수 \\times %.1f', fac(k)));
end
plot(ts, Yv(:,1), ':', 'LineWidth', 2.4, ...
     'DisplayName', sprintf('K_r 보정, 토크상수 \\times %.1f', fac(1)));
yline(1, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('각속도 [rad/s]');
legend('Location', 'southeast');
title('적분 상태를 넣으면 모델이 틀려도 오차가 0 이 된다');

%% 5. 상태궤환은 결국 무엇과 비슷한가
%
%  DC 모터 위치제어의 상태는 [각도, 각속도, 전류] 입니다.
%  상태궤환은
%
%      u = -k1*(각도) - k2*(각속도) - k3*(전류) + Kr*r
%
%  앞의 두 항을 보십시오.
%
%    - 각도에 비례해서 미는 것       = **P 제어**
%    - 각속도에 비례해서 빼는 것     = **D 제어** (각속도는 각도의 미분)
%
%  즉 **상태궤환은 PD 제어와 사촌**입니다.
%  다만 미분을 하는 대신 **이미 있는 상태를 쓰므로 잡음 증폭이 없습니다.**
%  7주차에서 고생한 미분 잡음 문제가 여기서는 안 생깁니다.
%
%  그리고 4절의 적분 상태를 더하면 **PID 와 같아집니다.**

fprintf('=== 5. 상태궤환 = PD (적분 상태를 더하면 PID) ===\n');
fprintf('  K = %s\n', mat2str(round(K, 2)));
fprintf('    k1 = %8.2f  <- 각도에 비례       (P 항)\n', K(1));
fprintf('    k2 = %8.2f  <- 각속도에 비례     (D 항)\n', K(2));
fprintf('    k3 = %8.2f  <- 전류에 비례       (전기 쪽 감쇠)\n', K(3));
fprintf('\n');
fprintf('  **차이점** — 7주차의 PD 는 각도를 미분해서 각속도를 만들었습니다.\n');
fprintf('  그래서 잡음이 증폭됐습니다. 상태궤환은 각속도를 **직접 재서** 씁니다.\n');
fprintf('  잴 수 없으면? 그것이 14주차의 관측기입니다.\n\n');

%% 6. 이번 실습의 정리
%
%  - 극배치는 **극점만** 옮긴다. 직류이득은 따로 맞춰야 한다
%  - Kr = 1/dcgain(A-BK, B, C, D) 로 앞단 보정
%  - Kr 은 **모델을 믿는 개루프식 보정**이다. 모델이 틀리면 오차가 남는다
%  - 확실히 없애려면 **적분 상태**를 하나 더 넣는다 (서보 문제)
%  - 상태궤환은 PD 와 사촌이고, 적분 상태를 더하면 PID 와 같다
%  - 다만 미분을 안 하므로 **잡음 증폭이 없다**
%
%  다음 실습 : W13_03_pendulum_balance.m 에서 거꾸로 선 진자를 세웁니다.

fprintf('=== 정리 ===\n');
fprintf('  Kr 은 빠르고 간단하지만 모델을 믿는다\n');
fprintf('  적분 상태는 느리지만 모델이 틀려도 맞다\n');
fprintf('  --> 사양에 "정상상태 오차 0" 이 있으면 적분 상태를 쓰십시오\n');
