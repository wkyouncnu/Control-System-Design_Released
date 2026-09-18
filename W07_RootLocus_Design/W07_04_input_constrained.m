%% W07_04_input_constrained.m
%  7주차 실습 (4) : 제어입력 한계를 사양에 넣고 설계하기
%
%  지금까지의 사양은 전부 "출력이 어떠해야 한다" 였습니다.
%  현장에서는 사양이 하나 더 붙습니다.
%
%      "제어입력이 이 값을 넘으면 안 된다"
%
%  모터는 정해진 전압까지만, 밸브는 완전히 열리는 데까지만,
%  추진기는 정해진 추력까지만 냅니다. 그 이상을 요구하는 설계는
%  종이 위에서만 맞고 실제로는 다르게 움직입니다.
%
%  이 실습에서는 그 한계를 **처음부터 사양에 넣고** 설계합니다.
%  그러면 답이 하나로 좁혀집니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 제어입력을 어떻게 사양에 넣는가?          -> 1절
%    Q2. 문제 1 - 비례이득 하나를 최종 결정한다    -> 2절
%    Q3. 문제 2 - PD 의 (z, K) 를 한꺼번에 고른다  -> 3절
%    Q4. 앱으로 하면 더 쉬운가?                    -> 4절
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

%% 1. 제어입력을 사양에 넣는다는 것
%
%  설계 절차 6단계는 그대로입니다. 다만 6단계(검증)에 항목이 하나 늘고,
%  그 항목이 5단계(이득 고르기)를 거꾸로 제한합니다.
%
%      기존 : 사양 -> 영역 -> 궤적 -> 교차 -> K -> 출력 검증
%      추가 :                                    -> 제어입력 검증
%              ^                                          |
%              +---- 넘으면 K 를 다시 줄인다 <-------------+
%
%  그리고 사양을 만족하는 K 가 여러 개일 때 고르는 기준이 생깁니다.
%
%      **사양을 만족하는 것 중에서 제어입력이 가장 작은 것**
%
%  왜 가장 작은 것인가? 세 가지 이유입니다.
%
%    - 구동기가 덜 뜨거워지고 덜 닳는다
%    - 전력을 덜 쓴다
%    - 모델이 조금 틀려도 한계에 부딪히지 않을 여유가 생긴다
%
%  계단 지령에서 제어입력이 가장 큰 순간은 보통 t = 0 입니다.
%  그때 오차가 가장 크기 때문입니다. 비례제어라면 아주 간단합니다.
%
%      u(0) = K * e(0) = K * (1 - 0) = K
%
%  즉 **비례제어에서 최대 제어입력은 이득 그 자체**입니다.

Gdemo = 1/(s*(s+2)*(s+5));
fprintf('=== 비례제어의 최대 제어입력은 K 그 자체 ===\n');
fprintf('     K     max|u| (계산)\n');
fprintf('   -----  --------------\n');
for K = [1 3 5 8]
    [~, ~, um] = ctrl_input(K, Gdemo);
    fprintf('   %5.1f  %14.3f\n', K, um);
end
fprintf('   --> 정확히 같습니다.\n\n');

%% 2. 문제 1 - 비례제어기 K 를 최종 결정한다
%
%      G(s) = 1 / (s(s+2)(s+5))     단위 피드백,  C(s) = K
%
%      사양 (다섯 개를 모두 만족해야 한다)
%        1) 폐루프가 안정할 것
%        2) 정착시간 (2 % 기준) Ts < 5.2 s
%        3) 오버슈트 Mp < 1 %
%        4) 계단 지령에 대한 정상상태 오차가 0
%        5) |u(t)| <= 5   (구동기 한계)
%
%      그리고 만족하는 K 중에서 max|u| 가 가장 작은 것을 고른다.

Gq = 1/(s*(s+2)*(s+5));

fprintf('=== 문제 1 : G = 1/(s(s+2)(s+5)) 에 비례제어 ===\n');

%  1단계. 사양 4)번은 손으로 먼저 확인합니다.
%  플랜트에 s 가 하나 있으니 타입 1 입니다. 타입 1 이면 계단 오차는 0 입니다
%  (5주차). 그러니 이 사양은 K 와 무관하게 저절로 만족됩니다.
fprintf('  사양 4) 검토 : 플랜트에 적분기(s)가 있으므로 타입 1\n');
fprintf('                 -> 계단 오차는 K 와 무관하게 0. 저절로 만족\n');

%  2단계. 안정 한계도 손으로 구합니다 (5주차 3차 조건).
%      s^3 + 7 s^2 + 10 s + K = 0  ->  7*10 > 1*K  ->  K < 70
fprintf('  사양 1) 검토 : 특성방정식 s^3 + 7s^2 + 10s + K = 0\n');
fprintf('                 안정 조건 7*10 > K  ->  K < 70\n');

%  3단계. 사양 2), 3) 을 s 평면으로 옮깁니다.
[zq, wq] = spec2pole(1, 5.2);
fprintf('  사양 2),3) 변환 : zeta >= %.4f ,  wn >= %.4f\n\n', zq, wq);

%  4~5단계. 이득을 훑습니다.
Tq  = rl_scan(1, Gq, linspace(0.5, 12, 1151), true);
okq = Tq.stable & Tq.ts < 5.2 & Tq.OS < 1 & Tq.umax <= 5;

fprintf('  사양별로 하나씩 걸러 보기\n');
fprintf('    안정               : K = %.2f ~ %.2f\n', ...
        min(Tq.K(Tq.stable)), max(Tq.K(Tq.stable)));
c2 = Tq.stable & Tq.ts < 5.2;
fprintf('    + 정착시간 5.2 s   : K = %.2f ~ %.2f   (이득이 작으면 느리다)\n', ...
        min(Tq.K(c2)), max(Tq.K(c2)));
c3 = c2 & Tq.OS < 1;
fprintf('    + 오버슈트 1 %%     : K = %.2f ~ %.2f   (이득이 크면 흔들린다)\n', ...
        min(Tq.K(c3)), max(Tq.K(c3)));
fprintf('    + 제어입력 5       : K = %.2f ~ %.2f\n\n', ...
        min(Tq.K(okq)), max(Tq.K(okq)));

subq = Tq(okq, :);
[~, jq] = min(subq.umax);
Kq = subq.K(jq);

fprintf('  최종 설계 : K* = %.3f\n', Kq);
fprintf('    정착시간   %.3f s   (요구 5.2 s 미만)\n', subq.ts(jq));
fprintf('    오버슈트   %.3f %%   (요구 1 %% 미만)\n', subq.OS(jq));
fprintf('    정상상태오차 %.6f   (요구 0)\n', subq.ess(jq));
fprintf('    최대 제어입력 %.3f  (요구 5 이하)\n\n', subq.umax(jq));

fprintf('  읽는 법\n');
fprintf('    사양 구간이 K = %.2f ~ %.2f 로 아주 좁습니다.\n', min(subq.K), max(subq.K));
fprintf('    아래쪽은 정착시간이, 위쪽은 제어입력이 막고 있습니다.\n');
fprintf('    두 사양을 조금만 더 조이면 답이 아예 없어집니다.\n');
fprintf('    이럴 때가 바로 비례제어를 버리고 보상기로 넘어갈 때입니다.\n\n');

tq = linspace(0, 10, 1200)';
[uq, ~] = ctrl_input(Kq, Gq, tq);

figure('Name','문제 1','Position',[80 80 1050 380]);
tiledlayout(1,3,'TileSpacing','compact');

nexttile
rlocus(Gq); hold on; sgrid(zq, wq);
xlim([-8 2]); ylim([-6 6]); grid on;
title('궤적과 사양 영역');

nexttile
plot(tq, step(feedback(Kq*Gq,1), tq), 'LineWidth', 2); hold on;
yline(1,'k--'); yline(1.01,'r:','LineWidth',1.5);
grid on; xlabel('시간 [s]'); ylabel('출력');
title(sprintf('계단응답 (K* = %.2f)', Kq));
legend('출력','목표','오버슈트 1 %','Location','southeast');

nexttile
plot(tq, uq, 'LineWidth', 2); hold on;
yline(5,'r--','LineWidth',1.5);
grid on; xlabel('시간 [s]'); ylabel('제어입력 u');
ylim([-1 6]);
title('제어입력과 한계선');
legend('u(t)','한계 5','Location','northeast');

%% 2-1. 사양별로 무엇이 K 를 막고 있는가
%
%  위에서 구간이 좁혀지는 과정을 그림으로 보면 이해가 빠릅니다.

figure('Name','사양이 K 를 좁히는 과정','Position',[100 100 950 400]);
yyaxis left
plot(Tq.K, Tq.ts, 'LineWidth', 2); hold on;
yline(5.2, '--', 'LineWidth', 1.5);
ylabel('정착시간 [s]'); ylim([0 12]);
yyaxis right
plot(Tq.K, Tq.OS, 'LineWidth', 2);
yline(1, ':', 'LineWidth', 1.5);
ylabel('오버슈트 [%]'); ylim([0 10]);
xlabel('이득 K'); grid on;
xline(min(subq.K), 'k-', 'LineWidth', 1.5);
xline(max(subq.K), 'k-', 'LineWidth', 1.5);
title('왼쪽 벽은 정착시간, 오른쪽 벽은 오버슈트와 제어입력');

%% 3. 문제 2 - PD 의 영점과 이득을 한꺼번에 고른다
%
%      G(s) = 1 / (s(s+2))     단위 피드백,  C(s) = K (s + z),  z > 0
%
%      사양
%        1) 폐루프가 안정할 것
%        2) 정착시간 (2 % 기준) Ts <= 2.0 s
%        3) 오버슈트 Mp <= 5 %
%        4) 계단 정상상태 오차 0  (타입 1 이므로 저절로 만족)
%        5) |u(t)| <= 3
%
%      만족하는 (z, K) 중 max|u| 가 가장 작은 조합을 고른다.
%
%  이번에는 고를 것이 둘이므로 표가 2차원이 됩니다.

Gp = 1/(s*(s+2));
z_list = [1 2 2.5 3 3.5 4 5 6 8 10];
K_list = linspace(0.2, 20, 400);

fprintf('=== 문제 2 : G = 1/(s(s+2)) 에 PD ===\n');
fprintf('  사양 : 안정, Ts <= 2.0 s, Mp <= 5 %%, |u| <= 3\n\n');
fprintf('     z     만족 K 구간      최선 K   Ts[s]   Mp[%%]   max|u|\n');
fprintf('   -----  --------------  --------  ------  ------  -------\n');

grid2 = [];
for z = z_list
    Tz = rl_scan(s+z, Gp, K_list, true);
    ok = Tz.stable & Tz.ts <= 2.0 & Tz.OS <= 5 & Tz.umax <= 3;
    if ~any(ok)
        fprintf('   %5.1f  만족하는 K 없음\n', z);
        continue
    end
    sub = Tz(ok, :);
    [~, j] = min(sub.umax);
    fprintf('   %5.1f  %6.2f ~ %5.2f  %8.2f  %6.2f  %6.2f  %7.3f\n', ...
            z, min(sub.K), max(sub.K), sub.K(j), sub.ts(j), sub.OS(j), sub.umax(j));
    grid2(end+1,:) = [z sub.K(j) sub.ts(j) sub.OS(j) sub.umax(j)]; %#ok<SAGROW>
end

[~, j2] = min(grid2(:,5));
z2 = grid2(j2,1);  K2 = grid2(j2,2);
fprintf('\n  최종 설계 : z* = %g , K* = %.2f , max|u| = %.3f\n\n', z2, K2, grid2(j2,5));

%% 3-1. PD 의 초기 제어입력에는 공식이 있다
%
%  표를 보면 max|u| 가 z 에 따라 크게 달라집니다. 왜 그런지 손으로 알 수 있습니다.
%
%  이 플랜트에서 계단 지령을 넣었을 때 t = 0 직후의 값은
%
%      e(0)  = 1        (아직 출력이 0 이므로)
%      de/dt(0) = -K    (출력이 K 의 기울기로 올라가기 시작하므로)
%
%  이고 PD 제어입력은 u = K(de/dt + z e) 이므로
%
%      u(0) = K (z - K)
%
%  입니다. 즉 **K 를 z 에 가깝게 잡으면 초기 제어입력이 사라집니다.**
%
%  다만 여기에는 빠진 항이 하나 있습니다. 솔직하게 짚고 갑니다.
%
%    - 계단 지령은 t = 0 에서 0 에서 1 로 **순간적으로** 뜁니다
%    - 이상적인 미분기는 그 순간의 기울기를 무한대로 봅니다
%    - 그래서 u(t) 안에는 t = 0 에 크기 K 짜리 임펄스가 하나 더 있습니다
%
%  실제 장치에서는 이 임펄스가 무한대가 되지 않습니다. 제어기의 대역폭이
%  유한하기 때문에 아주 높고 좁은 스파이크로 나타날 뿐입니다.
%  그 높이는 제어기를 얼마나 이상적으로 만드느냐에 달려 있어서,
%  설계 단계에서 z 와 K 를 비교하는 잣대로는 쓸 수 없습니다.
%
%  그래서 ctrl_input 은 임펄스를 뺀 **그 직후부터의 최대값**을 돌려줍니다.
%  후보들을 같은 잣대로 비교하는 것이므로 순위는 그대로 유효합니다.
%  이 문제 자체는 다음 실습(Lead 보상기)에서 정면으로 다룹니다.

fprintf('=== PD 초기 제어입력 공식 확인 : u(0) = K(z - K) ===\n');
fprintf('  (t = 0 의 임펄스를 뺀 값입니다. 위 설명 참고)\n');
fprintf('     z      K     공식 u(0)   계산 u(0)\n');
fprintf('   -----  -----  ----------  ----------\n');
for k = 1:size(grid2,1)
    zz = grid2(k,1); kk = grid2(k,2);
    [uu, ~] = ctrl_input(kk*(s+zz), Gp);
    fprintf('   %5.1f  %5.2f  %10.3f  %10.3f\n', zz, kk, kk*(zz-kk), uu(1));
end
fprintf('\n');

%% 3-2. 그런데 z* = 2 는 조심해서 봐야 합니다
%
%  플랜트 극점이 s = -2 입니다. z = 2 는 그 위에 정확히 영점을 놓는 것,
%  즉 3절에서 배운 **극점 상쇄** 입니다.
%
%  안정한 극점이니 금지는 아닙니다. 다만 실제 플랜트의 극점이 -2 가 아니라
%  -2.4 였다면 어떻게 되는지 확인해 두는 것이 옳습니다.

C2 = K2*(s+z2);
fprintf('=== 상쇄 설계의 강건성 확인 (z* = %g) ===\n', z2);
fprintf('    실제 극점    Ts[s]   Mp[%%]   max|u|\n');
fprintf('   -----------  ------  ------  -------\n');
for pr = [1.6 2.0 2.4 3.0]
    Gr = 1/(s*(s+pr));
    Tr = feedback(C2*Gr, 1);
    ir = stepinfo(Tr);
    [~, ~, ur] = ctrl_input(C2, Gr);
    fprintf('   %11.1f  %6.2f  %6.2f  %7.3f\n', -pr, ir.SettlingTime, ir.Overshoot, ur);
end

% 상쇄를 쓰지 않는 대안도 하나 뽑아 둡니다
alt = grid2(grid2(:,1) ~= z2, :);
[~, ja] = min(alt(:,5));
za = alt(ja,1); Ka = alt(ja,2);
Ca = Ka*(s+za);
fprintf('\n  상쇄를 피한 대안 : z = %g , K = %.2f , max|u| = %.3f\n', za, Ka, alt(ja,5));
fprintf('    같은 강건성 확인\n');
fprintf('    실제 극점    Ts[s]   Mp[%%]   max|u|\n');
fprintf('   -----------  ------  ------  -------\n');
for pr = [1.6 2.0 2.4 3.0]
    Gr = 1/(s*(s+pr));
    Tr = feedback(Ca*Gr, 1);
    ir = stepinfo(Tr);
    [~, ~, ur] = ctrl_input(Ca, Gr);
    fprintf('   %11.1f  %6.2f  %6.2f  %7.3f\n', -pr, ir.SettlingTime, ir.Overshoot, ur);
end
fprintf('\n  둘 다 무너지지 않습니다. 안정한 극점 상쇄는 이래서 실무에서도 씁니다.\n\n');

t2 = linspace(0, 4, 800)';
[u2, ~] = ctrl_input(C2, Gp, t2);
[ua, ~] = ctrl_input(Ca, Gp, t2);

figure('Name','문제 2','Position',[120 120 1050 380]);
tiledlayout(1,3,'TileSpacing','compact');

nexttile
rlocus(Gp*(s+z2)); hold on; rlocus(Gp*(s+za));
xlim([-12 2]); ylim([-8 8]); grid on;
title(sprintf('영점 z = %g 와 z = %g 의 궤적', z2, za));

nexttile
plot(t2, step(feedback(C2*Gp,1), t2), 'LineWidth', 2); hold on;
plot(t2, step(feedback(Ca*Gp,1), t2), 'LineWidth', 2);
yline(1,'k--'); yline(1.05,'r:');
grid on; xlabel('시간 [s]'); ylabel('출력'); ylim([0 1.3]);
legend(sprintf('z = %g, K = %.2f', z2, K2), sprintf('z = %g, K = %.2f', za, Ka), ...
       '목표','오버슈트 5 %','Location','southeast');
title('두 설계의 계단응답');

nexttile
plot(t2, u2, 'LineWidth', 2); hold on;
plot(t2, ua, 'LineWidth', 2);
yline(3,'r--'); yline(-3,'r--','HandleVisibility','off');
grid on; xlabel('시간 [s]'); ylabel('제어입력 u');
legend(sprintf('z = %g', z2), sprintf('z = %g', za), '한계 3','Location','northeast');
title('제어입력과 한계선');

%% 4. Control System Designer 앱으로 같은 일 하기
%
%  MATLAB 에는 근궤적 설계를 마우스로 하는 앱이 있습니다.
%
%  ---------------------------------------------------------------
%  controlSystemDesigner - 근궤적 설계 앱
%  ---------------------------------------------------------------
%    원리 : 근궤적, 계단응답, 보드선도를 한 화면에 띄우고
%           이득이나 극영점을 마우스로 끌면 모든 창이 동시에 갱신된다
%
%    입력 : controlSystemDesigner(G)          플랜트만 주고 시작
%           controlSystemDesigner(G, C)       제어기 초기값도 함께
%
%    출력 : 화면. 설계를 끝내면 Export 로 제어기를 워크스페이스에 내보낸다
%
%    쓰는 법
%      1) Root Locus 창에서 마우스로 이득(분홍 네모)을 끈다
%      2) 오른쪽 클릭 -> Design Requirements -> New 로 사양 영역을 겹친다
%      3) Add Pole or Zero -> Real Zero 로 PD 영점을 넣고 끌어 본다
%      4) Step 창에서 오버슈트와 정착시간을 실시간으로 확인한다
%
%    주의 세 가지
%      - 앱은 **제어입력을 보여 주지 않습니다.**
%        반드시 설계 후 ctrl_input 으로 따로 확인해야 합니다
%      - 마우스로 끈 값은 재현이 어렵습니다. 최종 값은 스크립트에 적어 두십시오
%      - 앱이 만든 제어기의 이득 표기가 K(s+z) 가 아니라 K(1+s/z) 일 수 있습니다.
%        Export 한 뒤 zpk 로 확인하십시오
%
%  아래 줄의 주석을 풀면 앱이 열립니다. (자동 실행에서는 막아 두었습니다)

fprintf('=== Control System Designer 로 해 보기 ===\n');
fprintf('  아래 명령을 명령창에 직접 입력하십시오.\n\n');
fprintf('    G = tf(1, [1 2 0]);\n');
fprintf('    controlSystemDesigner(G)\n\n');
fprintf('  그리고 이 스크립트가 구한 z* = %g , K* = %.2f 와 비교해 보십시오.\n', z2, K2);
fprintf('  앱으로 눈대중해서 고른 값과 얼마나 다른가요?\n\n');

% controlSystemDesigner(Gp);     % <- 주석을 풀면 앱이 열립니다

%% 5. 이번 실습의 정리
%
%  제어입력을 사양에 넣으면 세 가지가 달라집니다.
%
%    1) 답이 좁아진다
%       문제 1 에서 사양 구간이 K = 4.79 ~ 5.00 밖에 남지 않았습니다.
%       출력 사양만 봤다면 훨씬 넓어 보였을 것입니다
%
%    2) 고르는 기준이 생긴다
%       "만족하는 것 중 제어입력이 가장 작은 것" 이라는 규칙 하나로
%       무한히 많던 후보가 하나로 정해집니다
%
%    3) 손 공식이 하나 더 생긴다
%       비례제어  u(0) = K
%       PD 제어   u(0) = K (z - K)
%       설계 전에 대략 얼마가 필요할지 미리 알 수 있습니다
%
%  기억할 것
%
%      출력만 보고 설계를 끝내지 마십시오.
%      제어입력을 보지 않은 설계는 절반만 한 설계입니다.
%
%  다음 실습 : W07_05_lead_and_lag.m
%              PD 를 실제로 만들 수 없는 이유와 그 해결책을 봅니다.

fprintf('=== 정리 ===\n');
fprintf('  문제 1 : K* = %.3f  (max|u| = %.3f, 한계 5)\n', Kq, subq.umax(jq));
fprintf('  문제 2 : z* = %g , K* = %.2f  (max|u| = %.3f, 한계 3)\n', z2, K2, grid2(j2,5));
fprintf('\n  손 공식 : 비례제어 u(0) = K ,  PD u(0) = K(z - K)\n');
fprintf('  다음 : PD 는 실제로 만들 수 없다 -> W07_05\n');
