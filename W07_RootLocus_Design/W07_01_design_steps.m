%% W07_01_design_steps.m
%  7주차 실습 (1) : 근궤적 설계 6단계 - 비례제어 설계 세 문제
%
%  6주차에서는 근궤적을 "그리고 읽는" 법을 배웠습니다.
%  이번 주는 그것으로 **제어기를 고르는** 연습을 합니다.
%
%  오늘 푸는 문제는 전부 같은 모양입니다.
%
%      "이 플랜트에 비례이득 K 를 하나 붙인다.
%       사양을 만족하는 K 가 있는가? 있다면 얼마인가?"
%
%  세 문제를 풉니다. 그런데 셋 중 하나만 답이 있습니다.
%  나머지 둘이 왜 안 되는지를 아는 것이 오늘의 진짜 공부입니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 근궤적으로 설계하는 절차는?              -> 1절
%    Q2. 클릭 말고 숫자로 K 를 고르는 법은?       -> 2절
%    Q3. 예제 A - 사양을 만족하는 K 구간은?       -> 3절
%    Q4. 예제 B - 왜 첨두시간을 못 맞추는가?      -> 4절
%    Q5. 예제 C - 왜 오차 사양을 못 맞추는가?     -> 5절
%
%  대응하는 강의노트 : W07_LectureNote.mlx
%  대응하는 Simulink : W07_Design_Verify.slx
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

%% 1. 근궤적 설계 6단계
%
%  매번 이 순서로 합니다. 외우지 말고 몸에 붙이십시오.
%
%    1) 사양을 적는다        오버슈트 몇 %, 정착시간 몇 초, 오차 몇 %
%    2) 사양을 s 평면으로 옮긴다   %OS -> zeta ,  ts -> wn   (4주차 spec2pole)
%    3) 근궤적을 그린다      rlocus(L) ,  L 은 이득을 뺀 개루프
%    4) 사양 영역을 겹쳐 그린다    sgrid(zeta, wn)
%    5) 궤적이 영역을 지나는 곳의 이득을 읽는다
%    6) 검증한다             stepinfo 로 실측, 제어입력도 함께 확인
%
%  6단계를 빠뜨리는 사람이 많습니다. 반드시 하십시오.
%  5단계까지는 근사식이고, 진짜 답은 6단계에서 나옵니다.

fprintf('=== 근궤적 설계 6단계 ===\n');
steps = {'사양을 적는다', ...
         '사양을 s 평면으로 옮긴다 (spec2pole)', ...
         '근궤적을 그린다 (rlocus)', ...
         '사양 영역을 겹친다 (sgrid)', ...
         '교차 구간의 이득을 읽는다', ...
         '검증한다 (stepinfo + 제어입력)'};
for i = 1:numel(steps)
    fprintf('  %d) %s\n', i, steps{i});
end
fprintf('\n');

%% 2. 새 도구 두 개
%
%  6주차에서 쓴 rlocfind 는 마우스로 궤적 위를 찍는 명령입니다.
%  감을 잡기에는 좋지만 두 가지 불편이 있습니다.
%
%    - 손이 떨리면 값이 달라진다
%    - 스크립트를 자동으로 돌릴 수 없다 (클릭을 기다리며 멈춘다)
%
%  그래서 같은 일을 숫자로 하는 함수 두 개를 common 폴더에 넣어 두었습니다.
%
%  ---------------------------------------------------------------
%  rl_scan - 근궤적 위를 이득으로 훑어 성능표를 만든다
%  ---------------------------------------------------------------
%    원리 : K 를 촘촘히 바꿔 가며 매번 feedback 으로 폐루프를 닫고
%           pole / stepinfo / dcgain 으로 성능을 잰다. 전부 배운 명령이다.
%
%    입력 : rl_scan(C1, G, Kvec)        C1 은 이득을 뺀 제어기 (P 면 1)
%           rl_scan(C1, G, Kvec, true)  제어입력 최대치까지 계산
%
%    출력 : table. 한 행이 이득 하나
%           K  stable  zeta  wn  OS  ts  Tp  ess  umax
%
%    주의 : 표의 zeta 는 "지배극점"의 감쇠비다.
%           영점이 가까이 있으면 zeta 가 커도 오버슈트가 클 수 있다.
%           오버슈트는 항상 OS 열(stepinfo 실측)을 믿을 것.
%
%  ---------------------------------------------------------------
%  ctrl_input - 계단 지령에 대한 제어입력 u(t)
%  ---------------------------------------------------------------
%    원리 : U(s)/R(s) = C/(1+CG). 여기에 계단 1/s 를 곱해 역변환한다.
%
%    입력 : ctrl_input(C, G)      C 는 이득까지 포함한 제어기
%    출력 : [u, t, umax]
%
%    주의 : 출력만 보고 설계를 끝내면 안 된다.
%           구동기가 낼 수 없는 힘을 요구하는 설계는 종이 위에서만 맞다.
%
%  아래에서 실제로 한 번 써 봅니다.

G_demo = 1/(s*(s+2)*(s+5));
Tdemo  = rl_scan(1, G_demo, [1 3 5 8], true);
fprintf('=== rl_scan 사용 예 : G = 1/(s(s+2)(s+5)) 에 비례제어 ===\n');
disp(Tdemo);

[u_demo, t_demo] = ctrl_input(5, G_demo);
fprintf('  ctrl_input 사용 예 : K = 5 일 때 u(0) = %.2f  (= K, 오차가 1 이므로)\n\n', u_demo(1));

%% 3. 예제 A - 답이 있는 문제
%
%      G(s) = 1 / ((s+1)(s+3))    비례제어 D(s) = K
%
%      요구 : 오버슈트 10 % 이하,  정착시간 2 초 이하
%
%  먼저 사양을 s 평면으로 옮깁니다.

GA = 1/((s+1)*(s+3));
[zA, wA, sA] = spec2pole(10, 2);

fprintf('=== 예제 A : G = 1/((s+1)(s+3)) ===\n');
fprintf('  사양   : 오버슈트 10 %% 이하, 정착시간 2 s 이하\n');
fprintf('  변환   : zeta >= %.4f ,  wn >= %.4f\n', zA, wA);
fprintf('  목표극점 : %+.3f %+.3fj\n\n', real(sA), imag(sA));

% 이 시스템은 궤적이 세로 직선입니다. 왜 그런지 손으로 확인해 보십시오.
%   폐루프 특성방정식 : s^2 + 4s + (3+K) = 0
%   두 근의 합 = -4 이므로 복소근일 때 실수부는 항상 -2 로 고정됩니다.
fprintf('  특성방정식 : s^2 + 4s + (3+K) = 0\n');
fprintf('  근의 합이 -4 로 고정 -> 복소근의 실수부는 항상 -2\n');
fprintf('  즉 궤적의 복소 부분은 세로 직선입니다.\n\n');

TA = rl_scan(1, GA, linspace(0.5, 14, 541), true);
okA = TA.stable & TA.OS <= 10 & TA.ts <= 2;

fprintf('  사양을 만족하는 이득 : K = %.2f ~ %.2f\n', min(TA.K(okA)), max(TA.K(okA)));
fprintf('    아래쪽 한계는 정착시간, 위쪽 한계는 오버슈트가 정합니다.\n');

KA = round(max(TA.K(okA))*10)/10 - 0.4;      % 위쪽 한계에서 약간 여유를 둔 값
rowA = TA(find(TA.K >= KA, 1), :);
fprintf('  고른 값 K = %.1f\n', KA);
fprintf('    오버슈트 %.2f %%  (요구 10 %% 이하)\n', rowA.OS);
fprintf('    정착시간 %.3f s   (요구 2 s 이하)\n', rowA.ts);
fprintf('    최대 제어입력 %.2f\n', rowA.umax);
fprintf('    정상상태 오차 %.3f  <- 문제가 여기 있습니다\n\n', rowA.ess);

TA_cl = feedback(KA*GA, 1);
tA    = linspace(0, 4, 800)';
[uA, ~] = ctrl_input(KA, GA, tA);

figure('Name','예제 A','Position',[80 80 1000 380]);
tiledlayout(1,3,'TileSpacing','compact');

nexttile
rlocus(GA); hold on; sgrid(zA, wA);
xlim([-6 1]); ylim([-6 6]); grid on;
plot(real(sA), imag(sA), 'p', 'MarkerSize', 14, 'MarkerFaceColor', 'm');
title('궤적과 사양 영역');

nexttile
plot(tA, step(TA_cl, tA), 'LineWidth', 2); hold on;
yline(1, 'k--'); yline(1.1, 'r:', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('출력');
title(sprintf('계단응답 (K = %.1f)', KA));
legend('출력','목표','오버슈트 10 %','Location','southeast');

nexttile
plot(tA, uA, 'LineWidth', 2); grid on;
xlabel('시간 [s]'); ylabel('제어입력 u');
title('제어입력도 반드시 본다');

%% 3-1. 예제 A 가 남긴 숙제
%
%  사양은 만족했는데 정상상태 오차가 크게 남았습니다.
%
%    Kp = K * dcgain(G) = K/3 ,   ess = 1/(1+Kp)
%
%  이 플랜트는 적분기가 없는 타입 0 이라 비례제어로는 오차가 사라지지 않습니다
%  (5주차 내용). 이득을 키우면 오차는 줄지만 오버슈트가 커집니다.
%  즉 **비례제어 하나로는 과도응답과 정상상태 오차를 동시에 만족할 수 없습니다.**

fprintf('=== 예제 A 의 남은 문제 : 오차 ===\n');
fprintf('      K     Kp     오차     오버슈트\n');
fprintf('    -----  -----  -------  ---------\n');
for K = [2 4 8 20 50]
    Tk = feedback(K*GA, 1);
    fprintf('    %5.1f  %5.2f  %7.3f  %9.2f\n', ...
            K, K*dcgain(GA), 1-dcgain(Tk), getfield(stepinfo(Tk),'Overshoot')); %#ok<GFLD>
end
fprintf('    --> 오차를 줄이면 오버슈트가 커진다. 맞바꿈이다.\n\n');

%% 4. 예제 B - 궤적이 사양을 만날 수 없는 문제
%
%      G(s) = (s+2) / ((s+1)(s+5))    비례제어 D(s) = K
%
%      요구 : 오버슈트 15 % 이하,  첨두시간 Tp = 1.1 ~ 1.4 초
%
%  첨두시간은 진동의 빠르기입니다.
%
%      Tp = pi / wd ,   wd = 허수부
%
%  그러니 wd 가 pi/1.4 = 2.24 ~ pi/1.1 = 2.86 사이여야 합니다.
%  즉 폐루프 극점이 **복소수여야** 합니다.

GB = (s+2)/((s+1)*(s+5));
Tp_lo = 1.1; Tp_hi = 1.4;
wd_lo = pi/Tp_hi;  wd_hi = pi/Tp_lo;

fprintf('=== 예제 B : G = (s+2)/((s+1)(s+5)) ===\n');
fprintf('  요구 : 첨두시간 %.1f ~ %.1f s  ->  wd = %.2f ~ %.2f\n', ...
        Tp_lo, Tp_hi, wd_lo, wd_hi);

TB = rl_scan(1, GB, logspace(-2, 3, 400));
fprintf('  훑은 이득 범위 : K = %.2f ~ %.0f\n', min(TB.K), max(TB.K));
fprintf('  그 중 첨두시간이 존재한 경우 : %d 개\n', sum(~isnan(TB.Tp)));
fprintf('  최대 오버슈트 : %.4f %%\n\n', max(TB.OS));

%  왜 이런가? 실축 규칙(6주차)으로 손으로 확인할 수 있습니다.
fprintf('  실축 규칙으로 확인\n');
fprintf('    극점 : -1, -5      영점 : -2\n');
fprintf('    구간 (-2, -1) : 오른쪽에 극점 1 개  -> 홀수 -> 궤적 위\n');
fprintf('    구간 (-5, -2) : 오른쪽에 극점 1 + 영점 1 = 2 개 -> 짝수 -> 궤적 아님\n');
fprintf('    구간 (-inf,-5): 3 개 -> 홀수 -> 궤적 위\n');
fprintf('    => 가지 하나는 -1 에서 영점 -2 로, 다른 하나는 -5 에서 -inf 로\n');
fprintf('       두 가지가 **만나지 않으므로 복소수가 될 일이 없습니다.**\n\n');
fprintf('  결론 : 이 문제는 K 를 어떻게 잡아도 진동이 생기지 않습니다.\n');
fprintf('         오버슈트가 0 이라 "15 %% 이하" 는 저절로 만족하지만,\n');
fprintf('         첨두시간 사양은 **정의 자체가 성립하지 않습니다.**\n');
fprintf('         비례제어로는 불가능. 궤적 모양을 바꿔야 합니다.\n\n');

tB = linspace(0, 6, 600)';
figure('Name','예제 B','Position',[100 100 900 380]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
rlocus(GB); hold on; grid on;
xlim([-8 1]); ylim([-3 3]);
title('궤적이 실축을 벗어나지 않는다');

nexttile
hold on; grid on;
for K = [1 5 20 100]
    plot(tB, step(feedback(K*GB,1), tB), 'LineWidth', 2, ...
         'DisplayName', sprintf('K = %d', K));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력');
title('어떤 K 를 써도 진동이 없다');
legend('Location','southeast');

%% 5. 예제 C - 사양끼리 서로 싸우는 문제
%
%      G(s) = 5 / ((s+1)(s+2)(s+5))    비례제어 D(s) = K
%
%      요구 (1) 계단 정상상태 오차 5 % 이하
%      요구 (2) 감쇠비 0.35 이상
%
%  요구 (1) 을 먼저 손으로 풉니다. 타입 0 이므로
%
%      Kp = lim K*G(s) = K * 5/10 = K/2 ,   ess = 1/(1+Kp) <= 0.05
%      -> 1 + K/2 >= 20  ->  K >= 38

GC = 5/((s+1)*(s+2)*(s+5));
K_need = (1/0.05 - 1)/dcgain(GC);

fprintf('=== 예제 C : G = 5/((s+1)(s+2)(s+5)) ===\n');
fprintf('  손 계산 : Kp = K * %.2f ,  ess <= 0.05  ->  K >= %.1f\n', dcgain(GC), K_need);

%  이번에는 안정 한계를 손으로 구합니다 (5주차 3차 조건).
%      특성방정식 : s^3 + 8 s^2 + 17 s + (10 + 5K) = 0
%      안정 조건  : 8 * 17 > 1 * (10 + 5K)
fprintf('  특성방정식 : s^3 + 8 s^2 + 17 s + (10 + 5K) = 0\n');
fprintf('  안정 조건  : 8*17 > 10 + 5K   ->  K < %.2f\n', (8*17-10)/5);

TC = rl_scan(1, GC, linspace(0.5, 45, 600));
K_crit = min(TC.K(~TC.stable));
fprintf('  수치 확인  : 불안정해지는 첫 이득 K = %.2f\n\n', K_crit);

fprintf('  ** 충돌 **\n');
fprintf('    오차 사양이 요구하는 것 : K >= %.1f\n', K_need);
fprintf('    안정도가 허락하는 것    : K <  %.1f\n', K_crit);
fprintf('    겹치는 구간이 없습니다. 비례제어로는 절대 불가능합니다.\n\n');

okC = TC.stable & TC.zeta >= 0.35;
fprintf('  감쇠비 0.35 이상인 구간 : K = %.2f ~ %.2f\n', min(TC.K(okC)), max(TC.K(okC)));
fprintf('  그때의 오차            : %.3f ~ %.3f  (요구 0.05)\n', ...
        min(TC.ess(okC)), max(TC.ess(okC)));
fprintf('  --> 감쇠비를 지키면 오차가 %.0f 배 크고,\n', min(TC.ess(okC))/0.05);
fprintf('      오차를 지키려 하면 시스템이 발산합니다.\n\n');

figure('Name','예제 C','Position',[120 120 950 380]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
plot(TC.K, TC.ess, 'LineWidth', 2); hold on; grid on;
yline(0.05, 'r--', 'LineWidth', 1.5);
xline(K_crit, 'k:', 'LineWidth', 1.5);
xlabel('이득 K'); ylabel('정상상태 오차');
ylim([0 0.6]);
legend('오차','요구 0.05','안정 한계','Location','northeast');
title('오차는 안정 한계 안에서 0.05 에 닿지 못한다');

nexttile
plot(TC.K, TC.zeta, 'LineWidth', 2); hold on; grid on;
yline(0.35, 'r--', 'LineWidth', 1.5);
xline(K_crit, 'k:', 'LineWidth', 1.5);
xlabel('이득 K'); ylabel('지배극점 감쇠비');
legend('감쇠비','요구 0.35','안정 한계','Location','northeast');
title('감쇠비는 이득이 커지면 곧바로 무너진다');

%% 6. 이번 실습의 정리
%
%  세 문제를 풀었습니다.
%
%    예제 A  답이 있다.  K = 2.15 ~ 8.40
%            다만 정상상태 오차가 26 % 남는다.
%
%    예제 B  답이 없다.  궤적이 실축을 벗어나지 않아 진동 자체가 없다.
%            첨두시간 사양은 성립하지 않는다.
%
%    예제 C  답이 없다.  오차가 요구하는 이득이 안정 한계보다 크다.
%            사양끼리 정면으로 충돌한다.
%
%  세 경우 모두 원인이 같습니다.
%
%      **비례이득 K 는 궤적 위에서 점을 옮길 뿐, 궤적 자체는 못 바꾼다.**
%
%  그러니 궤적이 가지 않는 곳은 영원히 갈 수 없습니다.
%  다음 실습에서 궤적 자체를 옮기는 방법을 배웁니다.
%
%  다음 실습 : W07_02_pd_and_pi.m

fprintf('=== 정리 ===\n');
fprintf('  A : 성공 (K = %.2f ~ %.2f) . 다만 오차 %.0f %% 가 남는다\n', ...
        min(TA.K(okA)), max(TA.K(okA)), 100*rowA.ess);
fprintf('  B : 실패 . 궤적이 복소수로 가지 않아 첨두시간을 정의할 수 없다\n');
fprintf('  C : 실패 . 오차가 요구하는 K(%.0f) > 안정 한계(%.1f)\n', K_need, K_crit);
fprintf('\n  공통 원인 : 비례이득은 궤적 위를 움직일 뿐 궤적을 바꾸지 못한다\n');
fprintf('  해법      : 제어기에 극점과 영점을 더해 궤적을 옮긴다 -> W07_02\n');
