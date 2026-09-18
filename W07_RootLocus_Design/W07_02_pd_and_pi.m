%% W07_02_pd_and_pi.m
%  7주차 실습 (2) : PD 와 PI - 궤적을 옮기는 두 가지 방법
%
%  6주차에서 벽에 부딪혔습니다.
%
%      "오버슈트 20 %, 정착시간 2 초" 를 비례제어로는 만족할 수 없다.
%      궤적이 사양 영역을 지나지 않기 때문이다.
%
%  오늘 그 문제를 풉니다. 방법은 하나입니다. **궤적 자체를 옮긴다.**
%
%  이 스크립트에서 답할 질문
%    Q1. PD 제어기는 무엇을 추가하는가?          -> 2절
%    Q2. 영점 위치를 어떻게 고르는가?            -> 3절
%    Q3. 6주차의 실패한 문제를 풀 수 있는가?     -> 4절
%    Q4. PI 제어기는 무엇을 하는가?              -> 5절
%
%  대응하는 강의노트 : W07_LectureNote.mlx
%  대응하는 Simulink : W07_PD_Noise.slx
%
%  제어시스템설계 7주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 6주차에서 못 푼 문제
%
%  플랜트와 사양을 그대로 가져옵니다.

[G, p] = plant_dcmotor('position');
P_OS = 20;  ts = 2;
[zeta_min, wn_min, s_target] = spec2pole(P_OS, ts);

fprintf('=== 6주차에서 못 푼 문제 ===\n');
fprintf('  요구 : 오버슈트 %.0f %% 이하, 정착시간 %.0f s 이하\n', P_OS, ts);
fprintf('  목표 극점 : %+.3f %+.3fj\n', real(s_target), imag(s_target));

% 비례제어로 가능한지 다시 확인
Ks = linspace(1, 120, 400);
okP = false(size(Ks));
for i = 1:numel(Ks)
    ii = stepinfo(feedback(Ks(i)*G, 1));
    okP(i) = (ii.Overshoot <= P_OS) && (ii.SettlingTime <= ts);
end
if any(okP)
    fprintf('  비례제어로 가능합니다.\n\n');
else
    fprintf('  비례제어로는 만족하는 K 가 없습니다. (6주차 결론)\n\n');
end

%% 2. PD 제어기 : 영점을 하나 추가한다
%
%  PD 제어기의 전달함수는 이렇습니다.
%
%      C(s) = Kp + Kd*s = Kd*(s + Kp/Kd)
%
%  이것을 개루프에 곱하면
%
%      L(s) = C(s)*G(s) = Kd*(s + z)*G(s)        z = Kp/Kd
%
%  즉 **영점 s = -z 를 하나 추가**하고, 이득이 Kd 가 됩니다.
%
%  6주차에서 배운 대로
%
%      영을 추가하면 n - m 이 줄어 궤적이 왼쪽으로 당겨진다
%
%  왜 미분이 이런 일을 하는가 (직관)
%
%      비례제어는 "지금 얼마나 틀렸는가" 만 봅니다.
%      미분제어는 "얼마나 빨리 틀려지고 있는가" 를 봅니다.
%      빨리 다가가면 미리 브레이크를 밟는 셈이라 오버슈트가 줄고
%      진동이 잦아듭니다.
%
%      4주차에서 본 것과 같습니다. 감쇠란 속도를 되먹이는 일이고,
%      D 항이 바로 그 일을 합니다.
%
%  아래에서 영점 위치를 바꿔 가며 궤적이 어떻게 변하는지 봅니다.

z_list = [1 3 6 12];

figure('Name','PD 영점 위치에 따른 궤적');
tiledlayout(2,2,'TileSpacing','compact');
for i = 1:numel(z_list)
    nexttile
    rlocus(G*(s + z_list(i))); hold on;
    sgrid(zeta_min, wn_min);
    axis([-16 3 -10 10]);
    title(sprintf('영점 s = -%d', z_list(i)));
end

fprintf('=== 영점 위치와 궤적 ===\n');
fprintf('  영점이 원점에 가까울수록 궤적이 크게 왼쪽으로 당겨집니다.\n');
fprintf('  다만 너무 가까우면 그 영점이 응답에 직접 영향을 주어\n');
fprintf('  오버슈트가 오히려 커질 수 있습니다 (2주차 영점의 효과).\n\n');

%% 3. 영점 위치를 고르는 실용 지침
%
%  이론적으로 딱 떨어지는 공식은 없습니다. 몇 가지 지침이 있을 뿐입니다.
%
%      지침 1 : 플랜트의 느린 극점 근처에 둔다
%               그 극점의 나쁜 영향을 상쇄하는 효과가 있습니다.
%
%      지침 2 : 목표 극점의 실수부 근처에 둔다
%               궤적이 목표점을 지나도록 만들기 좋습니다.
%
%      지침 3 : 너무 원점에 가깝게 두지 않는다
%               영점이 지배극점보다 원점에 가까우면 오버슈트가 커집니다.
%
%  실무에서는 몇 개 후보를 놓고 다 해 본 뒤 고릅니다.
%  아래에서 그렇게 합니다.

fprintf('=== 영점 후보별 설계 결과 ===\n');
fprintf('   영점   찾은 K   목표와의 거리   오버슈트[%%]  정착시간[s]  판정\n');
fprintf('  -----  --------  -------------  ----------  -----------  ------\n');

best = struct('z',NaN,'K',NaN,'os',Inf,'ts',Inf,'ok',false);
for z = z_list
    L = G*(s + z);
    [Kz, cpz] = rlocfind(L, s_target);
    [~, ix] = sort(abs(real(cpz)));
    dist = abs(cpz(ix(1)) - s_target);

    T = feedback(Kz*L, 1);
    ii = stepinfo(T);
    ok = (ii.Overshoot <= P_OS) && (ii.SettlingTime <= ts);
    if ok, mk = '합격'; else, mk = '불합격'; end
    fprintf('  %5.0f  %8.3f  %13.3f  %10.1f  %11.3f  %s\n', ...
            z, Kz, dist, ii.Overshoot, ii.SettlingTime, mk);

    if ok && ii.Overshoot < best.os
        best = struct('z',z,'K',Kz,'os',ii.Overshoot,'ts',ii.SettlingTime,'ok',true);
    end
end
fprintf('\n');

if best.ok
    fprintf('  가장 좋은 조합 : 영점 s = -%d, K = %.3f\n', best.z, best.K);
    fprintf('    오버슈트 %.1f %%, 정착시간 %.3f s\n\n', best.os, best.ts);
else
    fprintf('  이 후보들 중 합격이 없습니다. 다른 영점 위치를 시도해야 합니다.\n\n');
    best.z = 6; best.K = 50;
end

%% 4. 설계 결과 검증
%
%  고른 PD 제어기로 실제 응답을 확인합니다.
%  비례제어와 나란히 놓고 비교합니다.

z_pd = best.z;  Kd = best.K;
Kp_pd = Kd * z_pd;                       % C(s) = Kd*s + Kp 이므로 Kp = Kd*z

C_pd = Kd*(s + z_pd);
T_pd = feedback(C_pd*G, 1);

% 비교 대상으로 쓸 비례제어
%   비례제어가 낼 수 있는 **가장 짧은 정착시간**을 찾습니다.
%   이것이 비례제어의 최선이므로, 이것마저 사양에 못 미치면
%   비례제어로는 불가능하다는 뜻이 됩니다.
tsP = zeros(size(Ks));
for i=1:numel(Ks), tsP(i) = stepinfo(feedback(Ks(i)*G,1)).SettlingTime; end
[~, iP] = min(tsP);
K_p_best = Ks(iP);
T_p = feedback(K_p_best*G, 1);
fprintf('=== 비례제어의 최선 ===\n');
fprintf('  정착시간이 가장 짧은 K = %.1f 일 때 정착시간 %.3f s\n', ...
        K_p_best, min(tsP));
fprintf('  요구는 %.0f s 이므로, 비례제어의 최선으로도 부족합니다.\n\n', ts);

t = 0:0.005:6;
figure('Name','P 제어 vs PD 제어');
plot(t, step(T_p,  t), 'LineWidth', 2); hold on;
plot(t, step(T_pd, t), 'LineWidth', 2);
yline(1, 'k--', 'LineWidth', 1.5);
yline(1+P_OS/100, 'r:', 'LineWidth', 1.5);
xline(ts, 'r:', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('각도 [rad]');
title('비례제어로는 못 하던 것을 PD 가 해낸다');
legend(sprintf('P 제어 (K=%.1f)', K_p_best), ...
       sprintf('PD 제어 (K_d=%.1f, z=%d)', Kd, z_pd), ...
       '목표값', '오버슈트 한계', '정착시간 한계', 'Location','southeast');

fprintf('=== PD 제어기 ===\n');
fprintf('  C(s) = %.3f*(s + %d) = %.3f*s + %.3f\n', Kd, z_pd, Kd, Kp_pd);
fprintf('  즉 Kp = %.3f, Kd = %.3f\n', Kp_pd, Kd);
ii_pd = stepinfo(T_pd);
ii_p  = stepinfo(T_p);
fprintf('  P  제어 : 오버슈트 %5.1f %%, 정착시간 %6.3f s\n', ii_p.Overshoot, ii_p.SettlingTime);
fprintf('  PD 제어 : 오버슈트 %5.1f %%, 정착시간 %6.3f s\n\n', ii_pd.Overshoot, ii_pd.SettlingTime);

%% 5. PI 제어기 : 원점에 극점을 추가한다
%
%  PI 제어기의 전달함수는 이렇습니다.
%
%      C(s) = Kp + Ki/s = Kp*(s + Ki/Kp) / s
%
%  즉 **원점에 극점을 하나, 그리고 영점을 하나** 추가합니다.
%
%      극점 s = 0     : 시스템 타입을 하나 올린다 -> 정상상태 오차 제거 (5주차)
%      영점 s = -Ki/Kp : 그 극점이 만드는 나쁜 영향을 완화한다
%
%  5주차에서 배운 대로 원점 극점은 궤적을 오른쪽으로 밀어 불안정하게 만듭니다.
%  그래서 PI 는 반드시 영점을 함께 붙입니다. 영점이 없으면 순수 적분기가 되어
%  거의 항상 불안정해집니다.
%
%  영점 위치를 고르는 지침
%
%      원점에 아주 가깝게 둡니다. 보통 지배극점의 1/10 정도입니다.
%      이유는 원점 극점과 영점이 거의 상쇄되어 궤적의 나머지 부분은
%      거의 그대로 두면서, 정상상태 오차만 없애기 위해서입니다.
%
%  우리 플랜트는 이미 타입 1 이라 계단 오차가 0 입니다.
%  그래서 PI 의 효과를 보려면 램프 입력을 봐야 합니다.

zi_list = [0.1 0.5 2];
Kp_pi = 20;

fprintf('=== PI 영점 위치의 영향 (램프 입력) ===\n');
fprintf('  영점    Kv      램프 오차   안정?\n');
fprintf('  -----  ------  ---------  -----\n');
tr = (0:0.01:20)';
figure('Name','PI 제어와 램프 추종');
for zi = zi_list
    C_pi = Kp_pi*(s + zi)/s;
    L_pi = C_pi*G;
    T_pi = feedback(L_pi, 1);
    stable = all(real(pole(T_pi)) < 0);
    Kv = dcgain(s*L_pi);
    if stable, stab = '예'; else, stab = '아니오'; end
    fprintf('  %5.1f  %6.2f  %9.4f  %5s\n', zi, Kv, 1/Kv, stab);
    if stable
        plot(tr, lsim(T_pi, tr, tr), 'LineWidth', 2); hold on;
    end
end
plot(tr, tr, 'k--', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('각도 [rad]');
title('PI 제어의 램프 추종');
xlim([0 20]); ylim([0 20]);

fprintf('\n');
fprintf('  P 제어(타입 1)의 램프 오차 : %.4f\n', 1/dcgain(s*(Kp_pi*G)));
fprintf('  --> PI 를 붙이면 타입 2 가 되어 램프 오차가 0 이 됩니다.\n');
fprintf('      단, 원점 극점 때문에 불안정해지기 쉬우므로 영점 위치가 중요합니다.\n\n');

%% 6. PD 와 PI 를 언제 쓰는가
%
%  선택 기준은 단순합니다. **무엇이 문제인가** 를 보면 됩니다.
%
%      과도응답이 문제다 (느리다, 진동한다)  -> PD
%          영점을 추가해 궤적을 왼쪽으로 당긴다
%
%      정상상태 오차가 문제다               -> PI
%          원점 극점을 추가해 타입을 올린다
%
%      둘 다 문제다                          -> PID
%          11주차에서 다룹니다
%
%  주의할 점
%
%      PD 는 정상상태 오차를 개선하지 못합니다. 영점은 타입을 바꾸지 않습니다.
%      PI 는 과도응답을 나쁘게 만듭니다. 극점을 추가하니 느려집니다.
%      둘은 서로 다른 문제를 푸는 도구이고, 서로를 대신할 수 없습니다.

fprintf('=== PD 는 정상상태 오차를 개선하지 못한다 ===\n');
fprintf('  P  제어의 타입 : %d\n', sum(abs(pole(K_p_best*G)) < 1e-9));
fprintf('  PD 제어의 타입 : %d  (영점은 타입을 바꾸지 않습니다)\n', ...
        sum(abs(pole(C_pd*G)) < 1e-9));
fprintf('  PI 제어의 타입 : %d  (원점 극점이 하나 늘었습니다)\n\n', ...
        sum(abs(pole((Kp_pi*(s+0.5)/s)*G)) < 1e-9));

%% 7. 이번 실습의 정리
%
%  1) PD 제어기 C(s) = Kd*(s + z) 는 영점을 하나 추가한다.
%     궤적이 왼쪽으로 당겨져 더 빠르고 더 안정해진다.
%
%  2) 영점 위치를 고르는 공식은 없다. 후보를 몇 개 놓고 다 해 본다.
%     너무 원점에 가까우면 오히려 오버슈트가 커진다.
%
%  3) 6주차에서 비례제어로 불가능했던 사양을 PD 로 만족시켰다.
%     "길을 바꾼다" 는 것이 이런 뜻이다.
%
%  4) PI 제어기 C(s) = Kp*(s + z)/s 는 원점 극점과 영점을 함께 추가한다.
%     타입이 올라가 정상상태 오차가 개선되지만 불안정해지기 쉽다.
%
%  5) PD 는 과도응답을, PI 는 정상상태 오차를 고친다. 서로 대신할 수 없다.
%
%  다음 실습 : W07_03_pd_design_practice.m
%              영점을 어디에 놓을 것인지 계산으로 정하고,
%              극점 상쇄가 언제 유용하고 언제 금지인지 배웁니다.
%              (PD 와 PI 를 실무에서 그대로 쓸 수 없는 이유와
%               그것을 고친 Lead·Lag 는 W07_05 에서 다룹니다)
