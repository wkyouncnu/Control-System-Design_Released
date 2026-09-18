%% W04_01_first_second_order.m
%  4주차 실습 (1) : 1차 시스템과 2차 시스템의 시간응답
%
%  지금까지 "빠르다", "진동한다" 를 감으로 말해 왔습니다.
%  이번 주에는 이것을 숫자로 적는 법을 배웁니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 1차 시스템은 숫자 몇 개로 설명되는가?        -> 2절
%    Q2. 2차 시스템은?                                -> 3절
%    Q3. 감쇠비가 응답 모양을 어떻게 바꾸는가?        -> 4절
%    Q4. 극점 위치와 사양은 어떻게 연결되는가?        -> 5절
%
%  대응하는 강의노트 : W04_LectureNote.mlx
%  대응하는 Simulink : W04_SecondOrder_Sweep.slx
%
%  제어시스템설계 4주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 왜 숫자로 적어야 하는가
%
%  "이 제어기가 좋습니다" 라고 하면 아무도 판단할 수 없습니다.
%  "오버슈트 8 %, 정착시간 1.2 초입니다" 라고 해야 판단이 됩니다.
%
%  그리고 설계는 반대 방향으로 갑니다.
%
%      "오버슈트 10 % 이하, 정착시간 2 초 이하로 만들어 주세요"
%
%  이런 요구를 받고 제어기를 만드는 것이 우리 일입니다.
%  그러려면 먼저 이 숫자들이 무엇인지, 그리고 극점 위치와 어떻게 연결되는지
%  알아야 합니다. 그것이 오늘의 내용입니다.

%% 2. 1차 시스템 : 숫자 하나면 끝난다
%
%  1차 시스템의 표준형은 이것입니다.
%
%      G(s) = 1 / (tau*s + 1)
%
%  tau 를 시정수(time constant)라고 하며, 이 하나가 모든 것을 정합니다.
%
%      극점        : s = -1/tau
%      63% 도달    : t = tau
%      상승시간    : 약 2.2*tau   (10% -> 90%)
%      정착시간 2% : 약 4*tau
%
%  중요한 점: 1차 시스템은 절대로 오버슈트가 없습니다.
%             극점이 실수 하나뿐이라 진동할 방법이 없기 때문입니다.

tau_list = [0.5 1 2];
t = 0:0.01:12;

figure('Name','1차 시스템');
h = gobjects(1, numel(tau_list));
fprintf('=== 1차 시스템 ===\n');
fprintf('   tau    극점    상승시간   정착시간(2%%)   오버슈트\n');
fprintf('  -----  ------  --------  ------------  --------\n');
for i = 1:numel(tau_list)
    tau = tau_list(i);
    G1 = 1/(tau*s + 1);
    h(i) = plot(t, step(G1, t), 'LineWidth', 2); hold on;

    info = stepinfo(G1);
    fprintf('  %5.1f  %6.2f  %8.2f  %12.2f  %8.1f\n', ...
            tau, pole(G1), info.RiseTime, info.SettlingTime, info.Overshoot);
end
yline(1, 'k--', 'LineWidth', 1.5);
yline(0.632, 'r:', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('출력');
title('1차 시스템 : 시정수가 전부다');
legend(h, arrayfun(@(x) sprintf('\\tau = %.1f', x), tau_list, ...
       'UniformOutput', false), 'Location','southeast');

fprintf('  --> 상승시간이 대략 2.2*tau, 정착시간이 대략 4*tau 인지 확인하십시오.\n');
fprintf('  --> 오버슈트는 항상 0 입니다. 1차 시스템은 진동하지 못합니다.\n\n');

%% 3. 2차 시스템 : 숫자 두 개
%
%  2차 시스템의 표준형입니다.
%
%      G(s) = wn^2 / (s^2 + 2*zeta*wn*s + wn^2)
%
%  두 숫자가 모든 것을 정합니다.
%
%      wn   (고유진동수) : 얼마나 빠른가
%      zeta (감쇠비)     : 얼마나 진동하는가
%
%  극점은 이렇게 됩니다.
%
%      s = -zeta*wn +- j*wn*sqrt(1-zeta^2)
%
%  이 식을 뜯어보면 극점 위치의 의미가 그대로 보입니다.
%
%      실수부 = -zeta*wn            <- 얼마나 빨리 사라지는가
%      허수부 = wn*sqrt(1-zeta^2)   <- 얼마나 빨리 흔들리는가
%      원점까지 거리 = wn           <- 극점이 원점에서 멀수록 빠르다
%      실축과의 각도 = acos(zeta)   <- 각도가 클수록 많이 진동한다

wn = 2;
zeta_list = [0.1 0.3 0.5 0.707 1.0 1.5];
t2 = 0:0.01:15;

figure('Name','감쇠비의 영향');
tiledlayout(1,2,'TileSpacing','compact');

nexttile
for z = zeta_list
    G2 = wn^2/(s^2 + 2*z*wn*s + wn^2);
    plot(t2, step(G2, t2), 'LineWidth', 2); hold on;
end
yline(1, 'k--', 'LineWidth', 1.5); grid on;
xlabel('시간 [s]'); ylabel('출력');
title(sprintf('계단응답 (\\omega_n = %.1f 고정)', wn));
legend(arrayfun(@(z) sprintf('\\zeta = %.3f', z), zeta_list, ...
       'UniformOutput', false), 'Location','southeast');

nexttile
for z = zeta_list
    pl = pole(wn^2/(s^2 + 2*z*wn*s + wn^2));
    plot(real(pl), imag(pl), 'x', 'MarkerSize', 12, 'LineWidth', 3); hold on;
end
xline(0,'k-','LineWidth',1.5); yline(0,'k:');
grid on; axis equal; xlim([-3.5 0.5]); ylim([-2.5 2.5]);
xlabel('Real'); ylabel('Imag');
title('같은 경우의 극점 위치');

fprintf('=== 2차 시스템 (wn = %.1f 고정) ===\n', wn);
fprintf('   zeta   오버슈트[%%]  상승시간   정착시간(2%%)\n');
fprintf('  ------  ----------  --------  ------------\n');
for z = zeta_list
    G2 = wn^2/(s^2 + 2*z*wn*s + wn^2);
    info = stepinfo(G2);
    fprintf('  %6.3f  %10.1f  %8.2f  %12.2f\n', ...
            z, info.Overshoot, info.RiseTime, info.SettlingTime);
end
fprintf('\n');

%% 4. 감쇠비를 읽는 법
%
%  위 표에서 읽어야 할 것들입니다.
%
%      zeta = 0.1   : 오버슈트 73 %.  심하게 흔들린다
%      zeta = 0.5   : 오버슈트 16 %.  쓸 만한 수준
%      zeta = 0.707 : 오버슈트 4.3 %. 흔히 "좋은 설계"로 치는 값
%      zeta = 1.0   : 오버슈트 0 %.   진동 없이 가장 빠름 (임계감쇠)
%      zeta = 1.5   : 오버슈트 0 %.   진동은 없지만 오히려 느려짐 (과감쇠)
%
%  왜 0.707 을 좋아하는가:
%      오버슈트가 5 % 아래로 작으면서도 정착시간이 짧습니다.
%      게다가 이 값은 주파수응답에서 공진 피크가 사라지는 경계이기도 합니다.
%      (10주차에서 다시 만납니다)
%
%  극점 그림에서 확인할 것:
%      zeta 가 작으면 극점이 허수축에 가깝고 (많이 진동)
%      zeta 가 1 이면 극점이 실축 위에서 만나고 (진동 없음)
%      zeta 가 1 보다 크면 실축을 따라 갈라집니다.
%      모든 극점이 반지름 wn 인 원 위에 있다는 것도 확인하십시오 (zeta<1 인 동안).

%% 5. 사양과 극점을 잇는 두 개의 공식
%
%  이번 절이 4주차의 핵심이고, 6주차 설계의 출발점입니다.
%
%  (1) 오버슈트는 감쇠비만으로 정해진다
%
%      %OS = 100 * exp( -zeta*pi / sqrt(1-zeta^2) )
%
%      wn 이 전혀 없다는 점에 주목하십시오. 오버슈트는 zeta 만의 함수입니다.
%      이 식을 뒤집으면 "오버슈트 사양 -> 필요한 zeta" 가 나옵니다.
%
%          zeta = -ln(OS/100) / sqrt( pi^2 + ln(OS/100)^2 )
%
%  (2) 정착시간은 실수부만으로 정해진다
%
%      ts(2%) = 4 / (zeta*wn)
%
%      분모 zeta*wn 이 바로 극점의 실수부 크기입니다.
%      즉 "정착시간 사양 -> 극점이 얼마나 왼쪽에 있어야 하는가" 가 나옵니다.
%
%  이 두 공식을 함수로 만들어 두었습니다. spec2pole 입니다.
%  앞으로 6, 7, 13주차에서 계속 씁니다.

P_OS = 10;      % 오버슈트 10 % 이하
ts   = 2;       % 정착시간 2 초 이하

[zeta_min, wn_min, s_target] = spec2pole(P_OS, ts);

fprintf('=== 사양 -> 극점 조건 ===\n');
fprintf('  요구 : 오버슈트 %.0f %% 이하, 정착시간 %.1f 초 이하\n', P_OS, ts);
fprintf('  필요 : zeta >= %.4f,  wn >= %.4f rad/s\n', zeta_min, wn_min);
fprintf('  두 조건을 딱 맞게 만족하는 극점 : %.3f +- %.3fj\n', ...
        real(s_target), imag(s_target));
fprintf('  (실축과의 각도 = acos(zeta) = %.1f 도)\n\n', rad2deg(acos(zeta_min)));

%% 5-1. 공식이 맞는지 확인
%
%  구한 zeta, wn 으로 2차 시스템을 만들어 stepinfo 로 확인합니다.
%  사양에 딱 맞게 나와야 합니다.

G_target = wn_min^2/(s^2 + 2*zeta_min*wn_min*s + wn_min^2);
info_t = stepinfo(G_target);

fprintf('=== 확인 ===\n');
fprintf('  공식이 요구한 극점으로 만든 시스템의 실제 성능\n');
fprintf('    오버슈트   : %.2f %%   (요구 %.0f %%)\n', info_t.Overshoot, P_OS);
fprintf('    정착시간   : %.2f s    (요구 %.1f s)\n', info_t.SettlingTime, ts);
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    오버슈트는 요구값과 정확히 일치합니다. 이 공식은 정확한 식입니다.\n');
fprintf('    정착시간은 요구보다 짧게 나왔습니다. ts = 4/(zeta*wn) 은 포락선만\n');
fprintf('    보고 만든 근사식이라 실제보다 넉넉하게 잡아 주기 때문입니다.\n');
fprintf('    안전한 쪽으로 틀리므로 설계에 쓰기 좋습니다.\n\n');

t3 = 0:0.01:4;
figure('Name','사양을 만족하는 응답');
plot(t3, step(G_target, t3), 'LineWidth', 2); hold on;
yline(1, 'k--', 'LineWidth', 1.5);
yline(1 + P_OS/100, 'r:', 'LineWidth', 1.5);
xline(ts, 'r:', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('출력');
title(sprintf('사양에 딱 맞춘 응답 (\\zeta = %.3f, \\omega_n = %.2f)', zeta_min, wn_min));
legend('응답', '목표값', sprintf('오버슈트 한계 %.0f%%', P_OS), ...
       sprintf('정착시간 한계 %.0fs', ts), 'Location','southeast');

%% 6. 공식의 한계 : 극점이 셋이거나 영점이 있으면
%
%  위 두 공식은 "극점 두 개, 영점 없음" 이라는 가정에서 나왔습니다.
%  현실의 시스템은 대개 그렇지 않습니다.
%
%  그래도 공식을 쓰는 이유는 출발점이 필요하기 때문입니다.
%  공식으로 대략의 위치를 잡고, stepinfo 로 확인한 뒤 조정합니다.
%
%  아래에서 극점 하나를 더 붙였을 때 얼마나 어긋나는지 봅니다.

%  기준 2차 시스템의 극점 실수부는 -2 입니다. 여기에 극점을 하나 더 붙입니다.
%    먼 극점    s = -10 : 실수부가 5배 멀다  -> 빨리 사라져 영향이 작을 것
%    가까운 극점 s = -1 : 실수부가 절반이다 -> 가장 늦게 사라져 응답을 지배할 것

G_2nd = G_target;
G_3rd_far   = G_target * (10/(s+10));
G_3rd_close = G_target * (1/(s+1));

fprintf('=== 극점을 하나 더 붙이면 ===\n');
fprintf('  2차 (기준, 극점 실수부 -2) : 오버슈트 %5.1f %%, 정착시간 %.2f s\n', ...
        info_t.Overshoot, info_t.SettlingTime);
i2 = stepinfo(G_3rd_far);
fprintf('  + 먼 극점 s = -10 (5배 멀리): 오버슈트 %5.1f %%, 정착시간 %.2f s\n', ...
        i2.Overshoot, i2.SettlingTime);
i3 = stepinfo(G_3rd_close);
fprintf('  + 가까운 극점 s = -1 (절반) : 오버슈트 %5.1f %%, 정착시간 %.2f s\n', ...
        i3.Overshoot, i3.SettlingTime);
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    먼 극점은 거의 영향이 없습니다. 빨리 사라지기 때문입니다.\n');
fprintf('    가까운 극점은 정착시간을 %.1f 배로 늘렸습니다. 이제 이 극점이\n', ...
        i3.SettlingTime/info_t.SettlingTime);
fprintf('    가장 늦게 사라지므로 응답을 지배합니다. 이것을 지배극점이라 합니다.\n');
fprintf('    경험칙 : 다른 극점이 지배극점보다 5배 이상 왼쪽에 있으면 무시해도 됩니다.\n\n');

t4 = 0:0.01:8;
figure('Name','극점 추가의 영향');
plot(t4, step(G_2nd, t4), 'LineWidth', 2.5); hold on;
plot(t4, step(G_3rd_far, t4), '--', 'LineWidth', 2);
plot(t4, step(G_3rd_close, t4), ':', 'LineWidth', 2.5);
yline(1, 'k--'); grid on;
xlabel('시간 [s]'); ylabel('출력');
title('극점을 하나 더 붙였을 때');
legend('2차 (기준)', '먼 극점 추가 (s = -10)', '가까운 극점 추가 (s = -1)', ...
       'Location','southeast');

%% 7. 이번 실습의 정리
%
%  1) 1차 시스템은 시정수 tau 하나로 설명된다. 오버슈트는 항상 0.
%
%  2) 2차 시스템은 wn 과 zeta 두 개로 설명된다.
%       wn   = 얼마나 빠른가 = 극점이 원점에서 얼마나 먼가
%       zeta = 얼마나 진동하는가 = 극점이 실축에서 얼마나 벌어졌는가
%
%  3) 사양과 극점을 잇는 두 공식
%       오버슈트 -> zeta      (실축과의 각도를 정한다)
%       정착시간 -> zeta*wn   (극점이 얼마나 왼쪽에 있어야 하는지를 정한다)
%
%  4) 이 공식은 2차 근사다. 극점이 더 있으면 어긋나므로 stepinfo 로 확인해야 한다.
%     다만 다른 극점이 5배 이상 멀면 무시해도 좋다.
%
%  5) 6주차에서는 이 조건을 s 평면에 그려 놓고 (sgrid), 근궤적이 그 영역을
%     지나는 지점의 이득을 고르게 된다. 오늘 배운 것이 그 준비다.
%
%  다음 실습 : W04_02_spec_sweep.m
%              사양을 바꿔 가며 목표 극점 영역이 어떻게 움직이는지 봅니다.
