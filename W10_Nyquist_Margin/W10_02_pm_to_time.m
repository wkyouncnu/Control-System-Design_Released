%% W10_02_pm_to_time.m
%  10주차 실습 (2) : 주파수영역 사양과 시간영역 사양은 서로 번역된다
%
%  이 스크립트에서 답할 질문
%    Q1. 위상여유로 오버슈트를 짐작할 수 있는가?     -> 1절
%    Q2. 대역폭으로 빠르기를 짐작할 수 있는가?       -> 2절
%    Q3. 공진봉우리와 감쇠비는 어떤 관계인가?        -> 3절
%    Q4. 개루프 보드 선도에서 폐루프를 읽는 법       -> 4절
%    Q5. 감도함수는 무엇을 말해 주는가?              -> 5절
%
%  이번 실습의 핵심 메시지
%
%      4주차에서 배운 시간영역 사양(오버슈트, 정착시간)과
%      오늘 배운 주파수영역 사양(위상여유, 대역폭)은
%      **같은 것을 다르게 말하는 것**이다. 서로 번역할 수 있다.
%
%  대응하는 강의노트 : W10_LectureNote.mlx
%
%  제어시스템설계 10주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 위상여유와 오버슈트
%
%  2차 표준형에서는 위상여유와 감쇠비 사이에 정확한 관계식이 있습니다.
%  유도는 복잡하지만 결과는 간단합니다. 0 < zeta < 0.7 에서
%
%      zeta ~= PM[도] / 100
%
%  즉 **위상여유 50도면 감쇠비가 대략 0.5** 라는 뜻입니다.
%  그러면 4주차의 오버슈트 공식으로 바로 이어집니다.
%
%      %OS = 100*exp(-zeta*pi/sqrt(1-zeta^2))

fprintf('=== 위상여유로 감쇠비를 짐작하기 (2차 표준형) ===\n');
fprintf('     zeta    참 위상여유[도]   PM/100    오차\n');
fprintf('   -------  ---------------  --------  --------\n');
for z = [0.1 0.2 0.3 0.4 0.5 0.6 0.7]
    wn = 1;
    L2 = wn^2/(s*(s + 2*z*wn));       % 2차 표준형의 개루프
    [~, pm] = margin(L2);
    fprintf('   %7.2f  %15.2f  %8.4f  %8.4f\n', z, pm, pm/100, pm/100 - z);
end
fprintf('   --> zeta 가 0.6 이하면 PM/100 이 꽤 정확합니다.\n\n');

%% 1-1. 2차가 아니면 얼마나 어긋나는가
%
%  실제 시스템은 극점이 셋 이상이거나 영점이 있습니다.
%  그러면 공식이 어긋납니다. 얼마나 어긋나는지 직접 봅니다.

G = 1/(s*(s+1)^2);
Ks = linspace(0.1, 1.5, 40);
pm = zeros(size(Ks)); os = zeros(size(Ks)); os_est = zeros(size(Ks));

for i = 1:numel(Ks)
    [~, pm(i)] = margin(Ks(i)*G);
    ii = stepinfo(feedback(Ks(i)*G, 1));
    os(i) = ii.Overshoot;
    z = pm(i)/100;
    if z > 0 && z < 1
        os_est(i) = 100*exp(-z*pi/sqrt(1-z^2));
    else
        os_est(i) = NaN;
    end
end

figure('Name','위상여유와 오버슈트', 'Position',[80 80 900 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on; grid on;
plot(pm, os, 'LineWidth', 2.4);
plot(pm, os_est, '--', 'LineWidth', 2.4);
xlabel('위상여유 [도]'); ylabel('오버슈트 [%]');
legend('실제 (stepinfo)', '공식 예측 (\zeta = PM/100)', 'Location','northeast');
title('3차 시스템에서도 경향은 그대로');

nexttile; hold on; grid on;
t = (0:0.05:40)';
for K = [0.2 0.5 1.0]
    T = feedback(K*G, 1);
    [~, pmk] = margin(K*G);
    plot(t, step(T, t), 'LineWidth', 2, ...
         'DisplayName', sprintf('K = %.1f  (PM %.0f도)', K, pmk));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); legend('Location','southeast');
title('위상여유가 작을수록 많이 흔들린다');

fprintf('=== 3차 시스템에서의 예측 오차 ===\n');
fprintf('     K      PM[도]   실제 OS[%%]   공식 OS[%%]   차이\n');
fprintf('   -----  --------  -----------  -----------  --------\n');
for K = [0.2 0.4 0.6 0.8 1.0 1.2]
    [~, p_] = margin(K*G);
    ii = stepinfo(feedback(K*G,1));
    z = p_/100;
    oe = 100*exp(-z*pi/sqrt(1-z^2));
    fprintf('   %5.1f  %8.2f  %11.2f  %11.2f  %8.2f\n', K, p_, ii.Overshoot, oe, ii.Overshoot-oe);
end
fprintf('   --> 정확히 맞지는 않지만 **설계 초기에 짐작하기에는 충분합니다.**\n');
fprintf('       설계를 마치면 반드시 stepinfo 로 검증해야 합니다.\n\n');

%% 2. 대역폭과 빠르기
%
%  대역폭이란 폐루프의 크기가 -3 dB 로 떨어지는 주파수입니다.
%  "이 주파수까지는 지령을 따라간다" 는 뜻이므로 곧 **빠르기**입니다.
%
%  어림 관계
%      상승시간 tr ~= 1.8 / wBW
%      정착시간 ts ~= 4 / (zeta * wn),  그리고 wBW 는 wn 에 비례
%
%  즉 **대역폭이 두 배가 되면 대략 두 배 빨라집니다.**

bw = zeros(size(Ks)); tr = zeros(size(Ks)); ts = zeros(size(Ks));
for i = 1:numel(Ks)
    T = feedback(Ks(i)*G, 1);
    bw(i) = bandwidth(T);
    ii = stepinfo(T);
    tr(i) = ii.RiseTime;  ts(i) = ii.SettlingTime;
end

figure('Name','대역폭과 빠르기', 'Position',[80 80 900 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on; grid on;
plot(bw, tr, 'LineWidth', 2.4);
plot(bw, 1.8./bw, '--', 'LineWidth', 2);
xlabel('폐루프 대역폭 [rad s^{-1}]'); ylabel('상승시간 [s]');
legend('실제', '어림공식 1.8 / \omega_{BW}', 'Location','northeast');
title('대역폭이 넓을수록 빠르다');

nexttile; hold on; grid on;
wp = logspace(-2, 1, 400);
for K = [0.2 0.5 1.0]
    T = feedback(K*G, 1);
    semilogx(wp, 20*log10(squeeze(abs(freqresp(T, wp)))), 'LineWidth', 2, ...
             'DisplayName', sprintf('K = %.1f  (BW %.2f)', K, bandwidth(T)));
end
set(gca,'XScale','log');
yline(-3,'k--','HandleVisibility','off');
xlabel('주파수 [rad s^{-1}]'); ylabel('폐루프 크기 [dB]');
legend('Location','southwest');
title('-3 dB 를 지나는 곳이 대역폭');

fprintf('=== 대역폭과 시간응답 ===\n');
fprintf('     K     대역폭[rad s^-1]   상승시간[s]   1.8/BW    정착시간[s]\n');
fprintf('   -----  -----------------  -----------  --------  -----------\n');
for K = [0.2 0.5 1.0 1.4]
    T = feedback(K*G, 1);
    ii = stepinfo(T);  b = bandwidth(T);
    fprintf('   %5.1f  %17.3f  %11.2f  %8.2f  %11.2f\n', K, b, ii.RiseTime, 1.8/b, ii.SettlingTime);
end
fprintf('\n');

%% 3. 공진봉우리와 감쇠비
%
%  폐루프 크기 곡선의 최댓값을 Mr 이라고 합니다.
%  2차 표준형에서는 정확한 식이 있습니다 (zeta < 0.707 일 때만 존재).
%
%      Mr = 1 / (2*zeta*sqrt(1-zeta^2))
%      wr = wn * sqrt(1 - 2*zeta^2)
%
%  이것도 오버슈트와 같은 이야기입니다.
%  **봉우리가 크면 시간영역에서도 많이 넘어갑니다.**

fprintf('=== 공진봉우리, 감쇠비, 오버슈트 ===\n');
fprintf('     zeta    Mr[배]   Mr[dB]   wr/wn    오버슈트[%%]\n');
fprintf('   -------  -------  -------  -------  ------------\n');
for z = [0.1 0.2 0.3 0.5 0.707]
    T2 = 1/(s^2 + 2*z*s + 1);
    ii = stepinfo(T2);
    if z < 1/sqrt(2) - 1e-3
        Mr = 1/(2*z*sqrt(1-z^2));
        wr = sqrt(1-2*z^2);
        fprintf('   %7.3f  %7.3f  %7.2f  %7.3f  %12.2f\n', z, Mr, 20*log10(Mr), wr, ii.Overshoot);
    else
        fprintf('   %7.3f  %7s  %7s  %7s  %12.2f\n', z, '없음','-','-', ii.Overshoot);
    end
end
fprintf('   --> zeta >= 0.707 이면 봉우리가 아예 생기지 않습니다.\n');
fprintf('       실무에서 zeta = 0.707 을 좋아하는 이유 중 하나입니다.\n\n');

%% 4. 개루프 보드 선도만 보고 폐루프를 읽는 법
%
%  설계할 때 우리가 손에 쥐고 있는 것은 **개루프** L = C*G 입니다.
%  그런데 알고 싶은 것은 폐루프 성능입니다. 다행히 규칙이 간단합니다.
%
%      저주파 (|L| >> 1)  ->  T = L/(1+L) ~= 1     지령을 잘 따라간다
%      고주파 (|L| << 1)  ->  T ~= L                지령을 못 따라간다
%      교차주파수 근처    ->  여기서 성패가 갈린다
%
%  그래서 개루프 크기 곡선을 보면 폐루프가 어떻게 생겼는지 대충 압니다.
%
%      저주파를 높게  ->  정상상태 오차가 작다
%      교차주파수를 오른쪽으로  ->  빠르다
%      교차주파수에서 기울기를 -20 dB/dec 로  ->  위상여유가 확보된다

K = 0.5;
L = K*G;
T = feedback(L, 1);
w = logspace(-2, 2, 500);

figure('Name','개루프와 폐루프', 'Position',[80 80 880 420]);
semilogx(w, 20*log10(squeeze(abs(freqresp(L, w)))), 'LineWidth', 2); hold on; grid on;
semilogx(w, 20*log10(squeeze(abs(freqresp(T, w)))), 'LineWidth', 2);
yline(0, 'k--');
[~,~,~,wcp] = margin(L);
xline(wcp, ':', 'LineWidth', 1.8);
xlabel('주파수 [rad s^{-1}]'); ylabel('크기 [dB]');
legend('개루프 L', '폐루프 T = L/(1+L)', '0 dB', '교차주파수', 'Location','southwest');
title('개루프가 0 dB 를 지나는 곳 근처에서 폐루프가 꺾인다');

fprintf('=== 개루프 크기와 폐루프 크기 ===\n');
fprintf('     w[rad s^-1]   |L|[dB]   |T|[dB]   해석\n');
fprintf('   ------------  --------  --------  ------------------\n');
for wq = [0.05 0.2 wcp 1 5]
    ml = 20*log10(abs(freqresp(L,wq)));
    mt = 20*log10(abs(freqresp(T,wq)));
    if ml > 6,       txt = '잘 따라간다 (T ~ 1)';
    elseif ml < -6,  txt = '못 따라간다 (T ~ L)';
    else,            txt = '경계 구간';
    end
    fprintf('   %12.3f  %8.2f  %8.2f  %s\n', wq, ml, mt, txt);
end
fprintf('\n');

%% 5. 감도함수 — 왜 저주파 이득을 높이는가
%
%  두 가지 전달함수를 봅니다.
%
%      S(s) = 1/(1+L)      감도함수         : 외란과 오차에 관계
%      T(s) = L/(1+L)      상보감도함수     : 지령추종과 잡음에 관계
%
%  그리고 항상 성립하는 관계가 하나 있습니다.
%
%      S + T = 1
%
%  **이것이 제어의 근본적인 맞바꿈입니다.**
%  둘 다 작게 만들 수는 없습니다. 하나를 줄이면 다른 하나가 커집니다.
%
%  실무의 해법은 **주파수를 나눠 쓰는 것**입니다.
%
%      저주파 : S 를 작게  ->  외란 억제, 정상상태 오차 감소
%      고주파 : T 를 작게  ->  측정 잡음 억제

S = 1/(1+L);
figure('Name','감도함수와 상보감도함수', 'Position',[80 80 880 420]);
semilogx(w, 20*log10(squeeze(abs(freqresp(S, w)))), 'LineWidth', 2.4); hold on; grid on;
semilogx(w, 20*log10(squeeze(abs(freqresp(T, w)))), 'LineWidth', 2.4);
yline(0,'k--'); xline(wcp, ':', 'LineWidth', 1.8);
xlabel('주파수 [rad s^{-1}]'); ylabel('크기 [dB]');
legend('감도 S = 1/(1+L)  (외란)', '상보감도 T = L/(1+L)  (잡음)', ...
       '0 dB', '교차주파수', 'Location','east');
title('S 와 T 는 동시에 작아질 수 없다  (S + T = 1)');

fprintf('=== S + T = 1 확인 ===\n');
fprintf('     w[rad s^-1]     |S|      |T|     |S+T|\n');
fprintf('   ------------  -------  -------  --------\n');
for wq = [0.05 0.2 wcp 1 5]
    sv = freqresp(S, wq);  tv = freqresp(T, wq);
    fprintf('   %12.3f  %7.4f  %7.4f  %8.6f\n', wq, abs(sv), abs(tv), abs(sv+tv));
end
fprintf('   --> 어느 주파수에서든 합은 정확히 1 입니다.\n\n');

fprintf('  읽는 법\n');
fprintf('    저주파에서 |S| 가 작다 = 외란이 들어와도 출력이 별로 안 흔들린다\n');
fprintf('    고주파에서 |T| 가 작다 = 센서 잡음이 출력에 별로 안 나온다\n');
fprintf('    교차주파수 근처에서는 둘 다 1 근처라 어쩔 수 없다\n');
fprintf('    그래서 **교차주파수를 어디에 둘 것인가** 가 설계의 핵심이 됩니다.\n\n');

%% 6. 이번 실습의 정리
%
%   (1) 위상여유로 감쇠비를 짐작한다 : zeta ~= PM/100
%   (2) 대역폭으로 빠르기를 짐작한다 : tr ~= 1.8/wBW
%   (3) 공진봉우리 Mr 은 오버슈트와 같은 이야기다
%   (4) 개루프 크기 곡선의 저주파·교차주파수·고주파를 보면 폐루프가 보인다
%   (5) S + T = 1 은 피할 수 없는 맞바꿈이다. 주파수를 나눠 쓴다
%
%  이 번역표가 있어야 11주차에서 **시간영역 사양을 받고 주파수영역에서 설계**할 수 있습니다.
%
%  다음 실습
%    W10_03_run_simulink.m — Simulink 모델을 선형화해서 여유를 뽑아내기
