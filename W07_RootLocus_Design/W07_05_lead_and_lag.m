%% W07_05_lead_and_lag.m
%  7주차 실습 (5) : Lead 와 Lag - 실무에서 쓰는 보상기
%
%  W07_02 와 W07_03 에서 PD 와 PI 로 문제를 풀었습니다.
%  그런데 실무에서는 PD 와 PI 를 그대로 쓰지 않습니다. 이유가 있습니다.
%
%  이 스크립트에서 답할 질문
%    Q1. PD 를 그대로 못 쓰는 이유는?          -> 1절
%    Q2. Lead 보상기는 무엇이 다른가?          -> 2절
%    Q3. Lead 를 어떻게 설계하는가?            -> 3절
%    Q4. PI 를 그대로 못 쓰는 이유와 Lag 는?   -> 5절
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

[G, p] = plant_dcmotor('position');
P_OS = 20;  ts = 2;
[zeta_min, wn_min, s_target] = spec2pole(P_OS, ts);

%% 1. PD 를 그대로 쓸 수 없는 이유
%
%  PD 제어기는 이렇게 생겼습니다.
%
%      C(s) = Kd*(s + z)
%
%  분자에 s 가 있고 분모에는 없습니다. 이런 것을 부적절(improper)하다고 합니다.
%  분자 차수가 분모보다 높으면 실제로 만들 수 없습니다.
%
%  왜 만들 수 없는가
%
%      s 를 곱한다는 것은 미분한다는 뜻입니다.
%      완벽한 미분기는 물리적으로 존재하지 않습니다.
%      주파수가 높아질수록 이득이 무한히 커지기 때문입니다.
%
%  그리고 이것이 실제로 문제를 일으킵니다.
%
%      측정 신호에는 항상 잡음이 섞여 있습니다.
%      잡음은 빠르게 변하므로 미분하면 크게 증폭됩니다.
%      결과적으로 제어입력이 요동칩니다.
%
%  아래에서 PD 제어기의 이득이 고주파에서 어떻게 되는지 봅니다.

Kd = 18.9;  z_pd = 3;
C_pd = Kd*(s + z_pd);

w = logspace(-1, 4, 200);
mag_pd = zeros(size(w));
for i = 1:numel(w)
    mag_pd(i) = abs(evalfr(C_pd, 1j*w(i)));
end

fprintf('=== PD 제어기의 고주파 이득 ===\n');
fprintf('  주파수[rad/s]   제어기 이득\n');
fprintf('  -------------  ------------\n');
for wq = [1 10 100 1000 10000]
    fprintf('  %13.0f  %12.1f\n', wq, abs(evalfr(C_pd, 1j*wq)));
end
fprintf('  --> 주파수에 비례해 끝없이 커집니다.\n');
fprintf('      1000 rad/s 잡음이 %.0f 배로 증폭됩니다.\n\n', abs(evalfr(C_pd,1j*1000)));

%% 2. Lead 보상기 : PD 에 극점을 하나 붙인 것
%
%  해결책은 단순합니다. 분모에도 뭔가를 넣어 주면 됩니다.
%
%      Lead 보상기 :  C(s) = Kc * (s + z) / (s + p),      p > z
%
%  PD 와 비교하면
%
%      PD   : Kd*(s + z)           분모 없음. 고주파 이득이 무한대
%      Lead : Kc*(s + z)/(s + p)   분모 있음. 고주파 이득이 Kc 로 제한됨
%
%  이름이 Lead(앞섬)인 이유는 이 보상기가 위상을 앞서게 만들기 때문입니다.
%  위상 이야기는 9~10 주차에서 제대로 다룹니다. 오늘은 근궤적 관점으로만 봅니다.
%
%  근궤적 관점에서
%
%      영점 s = -z : 궤적을 왼쪽으로 당긴다 (PD 와 같은 효과)
%      극점 s = -p : 궤적을 오른쪽으로 민다 (원하지 않는 부작용)
%
%  그래서 극점을 **영점보다 훨씬 왼쪽에** 둡니다.
%  그러면 극점의 나쁜 영향이 작아지고 영점의 좋은 효과만 남습니다.
%
%  경험칙 : p 를 z 의 5~20 배로 둡니다.

p_list = [15 30 60];

fprintf('=== Lead 의 고주파 이득 (PD 와 비교) ===\n');
fprintf('  보상기            1000 rad~s 에서의 이득\n');
fprintf('  ----------------  ---------------------\n');
fprintf('  PD (분모 없음)     %21.1f\n', abs(evalfr(C_pd, 1j*1000)));
for pz = p_list
    C_lead = Kd*(s + z_pd)/(s + pz);
    fprintf('  Lead (p = %2d)     %21.1f\n', pz, abs(evalfr(C_lead, 1j*1000)));
end
fprintf('  --> Lead 는 고주파 이득이 Kc 로 제한됩니다. 잡음 증폭이 없습니다.\n\n');

figure('Name','PD vs Lead 의 주파수 특성');
mag_lead = zeros(numel(p_list), numel(w));
loglog(w, mag_pd, 'LineWidth', 2.5); hold on;
for i = 1:numel(p_list)
    for j = 1:numel(w)
        mag_lead(i,j) = abs(evalfr(Kd*(s+z_pd)/(s+p_list(i)), 1j*w(j)));
    end
    loglog(w, mag_lead(i,:), 'LineWidth', 2);
end
grid on; xlabel('주파수 [rad/s]'); ylabel('제어기 이득');
title('PD 는 고주파에서 무한히 커지고, Lead 는 멈춘다');
legend(['PD', arrayfun(@(x) sprintf('Lead p=%d', x), p_list, ...
        'UniformOutput', false)], 'Location','northwest');

%% 3. Lead 보상기 설계
%
%  절차는 6주차의 설계 절차와 같습니다. 다만 고를 것이 셋으로 늘었습니다.
%
%      z  : 영점 위치     -> PD 와 같은 지침 (플랜트의 느린 극점 근처)
%      p  : 극점 위치     -> z 의 5~20 배
%      Kc : 이득          -> rlocfind 로 읽는다
%
%  아래에서 후보들을 훑어 사양을 만족하는 조합을 찾습니다.

z_cand = [2 3 4];
p_cand = [15 30 60];

fprintf('=== Lead 후보 탐색 ===\n');
fprintf('   z    p    Kc      목표거리   오버슈트[%%]  정착시간[s]  판정\n');
fprintf('  ---  ---  ------  --------  ----------  -----------  ------\n');

bestL = struct('z',NaN,'p',NaN,'K',NaN,'os',Inf,'ts',Inf,'ok',false);
for zz = z_cand
    for pp2 = p_cand
        L = G*(s + zz)/(s + pp2);
        [Kc, cp] = rlocfind(L, s_target);
        [~, ix] = sort(abs(real(cp)));
        dist = abs(cp(ix(1)) - s_target);
        ii = stepinfo(feedback(Kc*L, 1));
        ok = (ii.Overshoot <= P_OS) && (ii.SettlingTime <= ts);
        if ok, mk = '합격'; else, mk = '불합격'; end
        fprintf('  %3.0f  %3.0f  %6.2f  %8.3f  %10.1f  %11.3f  %s\n', ...
                zz, pp2, Kc, dist, ii.Overshoot, ii.SettlingTime, mk);
        if ok && ii.SettlingTime < bestL.ts
            bestL = struct('z',zz,'p',pp2,'K',Kc, ...
                           'os',ii.Overshoot,'ts',ii.SettlingTime,'ok',true);
        end
    end
end
fprintf('\n');

if bestL.ok
    fprintf('  가장 좋은 조합 : z = %g, p = %g, Kc = %.3f\n', bestL.z, bestL.p, bestL.K);
    fprintf('    오버슈트 %.1f %%, 정착시간 %.3f s\n\n', bestL.os, bestL.ts);
else
    fprintf('  합격 조합이 없습니다. 후보 범위를 넓혀야 합니다.\n\n');
    bestL.z = 3; bestL.p = 30; bestL.K = 50;
end

%% 4. PD 와 Lead 를 나란히 비교
%
%  성능은 거의 같고, 고주파 이득만 다릅니다.
%  그래서 실무에서는 Lead 를 씁니다.

C_lead = bestL.K*(s + bestL.z)/(s + bestL.p);
T_lead = feedback(C_lead*G, 1);
T_pd   = feedback(C_pd*G, 1);

t = 0:0.005:5;
figure('Name','PD vs Lead 응답');
plot(t, step(T_pd,   t), 'LineWidth', 2.5); hold on;
plot(t, step(T_lead, t), '--', 'LineWidth', 2);
yline(1, 'k--', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('각도 [rad]');
title('PD 와 Lead 의 응답은 거의 같다');
legend('PD', 'Lead', '목표값', 'Location','southeast');

i_pd = stepinfo(T_pd);  i_ld = stepinfo(T_lead);

fprintf('=== PD vs Lead ===\n');
fprintf('  PD   : 오버슈트 %5.1f %%, 정착시간 %.3f s\n', i_pd.Overshoot, i_pd.SettlingTime);
fprintf('  Lead : 오버슈트 %5.1f %%, 정착시간 %.3f s\n', i_ld.Overshoot, i_ld.SettlingTime);
fprintf('\n');
fprintf('  고주파(1000 rad~s) 이득\n');
fprintf('    PD   %10.1f  <- 잡음을 이만큼 증폭한다\n', abs(evalfr(C_pd, 1j*1000)));
fprintf('    Lead %10.1f  <- Kc 에서 멈춘다\n', abs(evalfr(C_lead, 1j*1000)));
fprintf('\n');

%% 4-1. MATLAB 도 PD 의 제어입력은 계산하지 못합니다
%
%  제어입력을 구하려면 feedback(C, G) 를 만들어 step 을 부르면 됩니다.
%  그런데 PD 로 그렇게 하면 MATLAB 이 거부합니다.
%
%      "비적정(비인과적) 모델의 시간 응답을 시뮬레이션할 수 없습니다"
%
%  분자 차수가 분모보다 높아서 미래의 입력을 알아야 계산되는 꼴이기 때문입니다.
%  1절에서 "PD 는 실제로 만들 수 없다" 고 한 말이 여기서 그대로 확인됩니다.
%
%  이것 하나만으로도 실무에서 PD 대신 Lead 를 쓰는 이유가 충분합니다.

fprintf('  필요한 최대 제어입력\n');
try
    u_pd = max(abs(step(feedback(C_pd, G), t)));
    fprintf('    PD   %10.1f V\n', u_pd);
catch ME
    fprintf('    PD   계산 불가 : %s\n', ME.message);
    fprintf('         (분자 차수가 분모보다 높은 비인과적 모델이기 때문)\n');
end
u_ld = max(abs(step(feedback(C_lead, G), t)));
fprintf('    Lead %10.1f V   <- 이득 Kc = %.0f 이 크기 때문\n', u_ld, bestL.K);
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    이 Lead 조합은 성능이 PD 보다 좋고 잡음 증폭도 훨씬 적습니다.\n');
fprintf('    그러나 이득 Kc 가 커서 제어입력이 매우 큽니다.\n');
fprintf('    실제 구동기가 %.0f V 를 낼 수 없다면 이 설계는 쓸 수 없습니다.\n', u_ld);
fprintf('    극점 p 를 작게(예: 15) 잡으면 Kc 가 줄어 제어입력도 줄어듭니다.\n');
fprintf('    성능과 제어입력을 함께 보고 골라야 한다는 뜻입니다.\n\n');

% 극점 위치에 따른 이득과 제어입력의 맞바꿈
fprintf('=== 극점 p 에 따른 맞바꿈 (z = %g 고정) ===\n', bestL.z);
fprintf('    p      Kc     최대입력[V]  오버슈트[%%]  정착시간[s]\n');
fprintf('  -----  -------  -----------  ----------  -----------\n');
for pq = p_cand
    Lq = G*(s + bestL.z)/(s + pq);
    Kq = rlocfind(Lq, s_target);
    Cq = Kq*(s + bestL.z)/(s + pq);
    iq = stepinfo(feedback(Cq*G, 1));
    uq = max(abs(step(feedback(Cq, G), t)));
    fprintf('  %5.0f  %7.1f  %11.1f  %10.1f  %11.3f\n', ...
            pq, Kq, uq, iq.Overshoot, iq.SettlingTime);
end
fprintf('  --> p 를 키우면 성능은 좋아지지만 제어입력이 커집니다.\n\n');

%% 5. Lag 보상기 : PI 의 실용 버전
%
%  PI 제어기는 이렇게 생겼습니다.
%
%      C(s) = Kp*(s + z)/s
%
%  분모의 s 가 순수 적분기입니다. 이것도 문제가 있습니다.
%
%      (1) 원점 극점은 궤적을 오른쪽으로 밀어 불안정하게 만든다 (5주차)
%      (2) 적분기는 포화와 만나면 와인드업을 일으킨다 (11주차)
%
%  Lag 보상기는 극점을 원점이 아니라 **원점 아주 가까이**에 둡니다.
%
%      Lag 보상기 : C(s) = Kc*(s + z)/(s + p),      p < z,  p 는 아주 작다
%
%  Lead 와 식이 같은데 부등호만 반대입니다.
%
%      Lead : p > z  (극점이 영점보다 왼쪽)  -> 과도응답 개선
%      Lag  : p < z  (극점이 영점보다 오른쪽) -> 정상상태 오차 개선
%
%  Lag 의 효과
%
%      저주파 이득이 z/p 배로 커진다 -> 정상상태 오차가 그만큼 줄어든다
%      그런데 극점이 원점은 아니므로 오차가 완전히 0 이 되지는 않는다
%      대신 불안정해질 위험이 훨씬 적다
%
%  즉 Lag 는 "오차를 완전히 없애지는 못하지만 안전하게 크게 줄이는" 타협입니다.

fprintf('=== Lag 보상기의 저주파 이득 ===\n');
fprintf('   z     p     z~p 비   DC 이득 증가\n');
fprintf('  ----  -----  -------  ------------\n');
for zl = [0.5 1 2]
    pl = zl/10;
    C_lag = (s + zl)/(s + pl);
    fprintf('  %4.1f  %5.2f  %7.1f  %12.2f\n', zl, pl, zl/pl, dcgain(C_lag));
end
fprintf('  --> DC 이득이 z~p 배로 커집니다. 그만큼 정상상태 오차가 줄어듭니다.\n\n');

%% 5-1. Lag 를 붙여 램프 오차 줄이기
%
%  우리 플랜트는 타입 1 이라 계단 오차는 이미 0 입니다.
%  램프 오차를 봅니다.

Kbase = 20;
zl = 1;  pl = 0.1;
C_lag = Kbase*(s + zl)/(s + pl);

fprintf('=== Lag 로 램프 오차 줄이기 ===\n');
Kv_p   = dcgain(s*(Kbase*G));
Kv_lag = dcgain(s*(C_lag*G));
fprintf('  P 제어      : Kv = %8.3f -> 램프 오차 %.4f\n', Kv_p, 1/Kv_p);
fprintf('  Lag 붙임    : Kv = %8.3f -> 램프 오차 %.4f\n', Kv_lag, 1/Kv_lag);
fprintf('  오차가 %.1f 배 줄었습니다 (z~p 비인 %.0f 과 같습니다)\n', ...
        Kv_lag/Kv_p, zl/pl);
if all(real(pole(feedback(C_lag*G,1))) < 0), lagstab = '예'; else, lagstab = '아니오'; end
fprintf('  안정한가? %s\n\n', lagstab);

tr = (0:0.02:30)';
figure('Name','Lag 로 램프 오차 줄이기');
plot(tr, lsim(feedback(Kbase*G,1), tr, tr), 'LineWidth', 2); hold on;
plot(tr, lsim(feedback(C_lag*G,1), tr, tr), 'LineWidth', 2);
plot(tr, tr, 'k--', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('각도 [rad]');
title('Lag 보상기가 램프 추종 오차를 줄인다');
legend('P 제어', 'Lag 보상', '목표(램프)', 'Location','northwest');
xlim([0 30]); ylim([0 30]);

%% 6. 네 가지 보상기 정리
%
%      이름   전달함수                 하는 일               부작용
%      ----  ----------------------  --------------------  ------------------
%      P     Kp                      이득만 조절            아무것도 못 고침
%      PD    Kd*(s+z)                과도응답 개선          고주파 잡음 증폭
%      Lead  Kc*(s+z)/(s+p), p>z     과도응답 개선          거의 없음 (실무용)
%      PI    Kp*(s+z)/s              정상상태 오차 제거     불안정, 와인드업
%      Lag   Kc*(s+z)/(s+p), p<z     정상상태 오차 감소     응답이 조금 느려짐
%
%  고르는 법
%
%      과도응답이 문제      -> Lead
%      정상상태 오차가 문제 -> Lag
%      둘 다 문제           -> Lead-Lag (둘을 직렬로)
%      오차를 완전히 0 으로 -> PI 또는 PID (11주차)
%
%  Lead 와 Lag 는 식이 같고 부등호만 다릅니다.
%  이 한 가지만 기억하면 둘을 헷갈리지 않습니다.
%
%      Lead : 극점이 영점보다 왼쪽 (p > z)
%      Lag  : 극점이 영점보다 오른쪽 (p < z)

fprintf('=== 네 보상기의 극영점 배치 ===\n');
ctrls = { 'PD',   Kd*(s+3)
          'Lead', bestL.K*(s+bestL.z)/(s+bestL.p)
          'PI',   20*(s+0.5)/s
          'Lag',  C_lag };
for i = 1:4
    Ci = ctrls{i,2};
    fprintf('  %-5s : 영점 ', ctrls{i,1});
    zz = zero(Ci);
    if isempty(zz), fprintf('없음      '); else, fprintf('%+7.3f  ', zz); end
    fprintf('극점 ');
    pp3 = pole(Ci);
    if isempty(pp3), fprintf('없음'); else, fprintf('%+7.3f  ', pp3); end
    fprintf('\n');
end
fprintf('\n');

%% 7. 이번 실습의 정리
%
%  1) PD 는 부적절(improper)해서 실제로 만들 수 없다.
%     고주파 이득이 무한히 커져 잡음을 증폭한다.
%
%  2) Lead 는 PD 에 극점을 하나 붙여 그 문제를 고친 것이다.
%     극점을 영점보다 5~20 배 왼쪽에 두면 성능은 거의 같으면서
%     고주파 이득은 제한된다.
%
%  3) PI 는 원점 극점 때문에 불안정해지기 쉽고 와인드업 문제가 있다.
%
%  4) Lag 는 극점을 원점 대신 원점 근처에 두어 그 위험을 줄인 것이다.
%     오차가 완전히 0 이 되지는 않지만 z/p 배만큼 줄어든다.
%
%  5) Lead 와 Lag 는 식이 같고 부등호만 다르다.
%     Lead 는 p > z, Lag 는 p < z.
%
%  다음 실습 : W07_06_run_simulink.m
%              PD 의 잡음 증폭 문제를 Simulink 에서 직접 확인하고,
%              Lead 로 바꾸면 어떻게 달라지는지 봅니다.
