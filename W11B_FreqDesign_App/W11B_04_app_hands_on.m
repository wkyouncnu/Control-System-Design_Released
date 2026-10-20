%% W11B_04 — 앱에서 손으로 끌어 보기 : 끌면 무엇이 변하는가
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 7절 ~ 7-4절에 대응합니다.
%
% 이번 실습의 핵심 메시지
%
%     controlSystemDesigner 는 "답을 주는 도구" 가 아니라
%     "내가 고친 것이 사양에 어떻게 비치는지 즉시 보여 주는 거울" 이다.
%     그러므로 끌기 전에 **무엇이 어떻게 변할지** 알고 있어야 한다.
%
% 이 스크립트는 앱에서 끌면 일어나는 일을 **숫자로** 재현합니다.
% 앱을 옆에 띄워 놓고 같은 조작을 해 보면서 읽으십시오.
%
% 바꿔 볼 것
%   - 1절의 open_app 을 true 로 (앱이 열립니다)
%   - 3절의 zv 에 1, 40 을 넣어 보기
%   - 5절의 pm_spec 과 ess_spec 을 바꿔 보기

clear; clc; close all;
s = tf('s');

%% 0. 경로 자동 등록
if isempty(which('plant_msd'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end

%% 1. 앱 열기
%  `controlSystemDesigner`
%
%  - **원리** — 루프의 제어기 $C$ 를 편집하면 개루프 보드, 근궤적, 폐루프
%    계단응답을 **즉시 다시 그려** 보여 준다. 계산은 우리가 손으로 한 것과 같다
%  - **입력** — 플랜트 전달함수 하나 (또는 `controlSystemDesigner(G, C)`)
%  - **출력** — 없다. 화면만 띄운다. 결과는 Export 로 작업공간에 내보낸다
%  - **주의** — 앱이 편집하는 것은 **제어기 $C$ 뿐**이다. 플랜트는 못 바꾼다.
%    그리고 유리함수만 다룬다 (수송지연은 Simulink 에서 확인해야 한다)
%  - **예제** — 아래 open_app 을 true 로 바꾸면 열린다

G = 1/(s*(s+1));                % 오늘의 플랜트

open_app = false;               % <-- true 로 바꾸면 앱이 열린다
if open_app
    controlSystemDesigner(G);
end

fprintf('앱에서 처음 해 둘 세 가지\n');
fprintf('  (1) Preferences 에서 Frequency 단위를 rad/s 로\n');
fprintf('  (2) New Plot 으로 폐루프 보드(r->y) 와 제어입력(r->u) 창을 추가\n');
fprintf('  (3) Design Requirements 로 사양 선을 그려 놓기 (5절에서 숫자를 계산한다)\n');

%% 2. K 를 끌어도 위상 곡선은 꼼짝하지 않는다
%  왜 그런가 — C = K 이면 L = K*G 이고 K 가 실수 양수이므로
%
%      angle(L) = angle(K) + angle(G) = 0 + angle(G)
%
%  위상은 **플랜트가 전부 정합니다.** K 는 크기만 올립니다.
%  그런데 PM 은 바뀝니다. 곡선이 움직여서가 아니라 **읽는 자리가 옮겨가서** 입니다.

K7 = [25; 100; 400];
n7 = numel(K7);
wc7 = zeros(n7,1); ph7 = zeros(n7,1); pm7 = zeros(n7,1);

for k = 1:n7
    [~, pm7(k), ~, wc7(k)] = margin(K7(k)*G);
    ph7(k) = angle(evalfr(G, 1i*wc7(k)))*180/pi;    % 플랜트만의 위상
end

table(K7, wc7, ph7, 180 + ph7, pm7, ...
    'VariableNames', {'K', 'wc', 'G의_위상_deg', '180_더하기', 'PM_deg'})

% 읽는 법
%   - 셋째 열에는 K 가 전혀 들어가지 않았다. **플랜트 G 하나의 위상**이다
%   - 그런데 넷째 열(180 + 그 위상) 과 다섯째 열(PM) 이 완전히 같다
%   => PM 은 플랜트 위상 곡선 위의 한 점을 읽은 값일 뿐이다

wp = logspace(-1, 3, 800);
ph_G = squeeze(angle(freqresp(G, wp)))*180/pi;

tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
for k = 1:n7
    semilogx(wp, 20*log10(K7(k)*squeeze(abs(freqresp(G, wp)))), 'LineWidth', 2);
end
set(gca, 'XScale', 'log');
yline(0, 'k--', 'LineWidth', 1.5);
plot(wc7, zeros(n7,1), 'ro', 'MarkerSize', 9, 'LineWidth', 2);
xlabel('주파수 [rad/s]'); ylabel('|L| [dB]');
legend('K=25', 'K=100', 'K=400', '0 dB', 'Location', 'southwest');
title('K 를 끌면 크기 곡선이 위아래로 통째로 움직인다');

nexttile; hold on; grid on;
semilogx(wp, ph_G, 'LineWidth', 2.5, 'Color', [0 0.25 0.6]);
set(gca, 'XScale', 'log');
yline(-180, 'k--', 'LineWidth', 1.5);
plot(wc7, ph7, 'ro', 'MarkerSize', 9, 'LineWidth', 2);
xlabel('주파수 [rad/s]'); ylabel('angle(L) [deg]');
title('위상 곡선은 하나뿐이다 — 움직이는 것은 빨간 표시점이다');

%% 3. 동그라미(영점) 를 왼쪽으로 끌면 — 좋아지는 것과 나빠지는 것
%  영점을 왼쪽으로 옮기면 atan(w/z) 에서 z 가 작아져 같은 w 에서 각이 커집니다.
%  즉 **위상을 더 일찍, 더 많이** 줍니다. PM 이 올라갑니다.
%
%  대가가 있습니다. Lead 제어기의 Kv 안에 영점 위치가 들어 있습니다.
%
%      C = (K/alpha)*(s+z)/(s+p)  =>  C(0) = (K/alpha)*(z/p)
%
%  z 를 작게 하면 C(0) 이 작아지고, Kv = lim s*C*G 도 같이 작아집니다.
%  **정상상태오차 사양이 깨집니다.**

zv = [20; 10; 6; 3; 1.5];       % <-- 1, 40 을 넣어 보기
n8 = numel(zv);

pm8 = zeros(n8,1); wc8 = zeros(n8,1); os8 = zeros(n8,1); kv8 = zeros(n8,1);

for k = 1:n8
    Ck = 754.86*(s + zv(k))/(s + 45.88);
    Lk = Ck*G;
    [~, pm8(k), ~, wc8(k)] = margin(Lk);
    os8(k) = stepinfo(feedback(Lk, 1)).Overshoot;
    kv8(k) = dcgain(s*Lk);
end

table(zv, pm8, wc8, os8, kv8, 1./kv8, ...
    'VariableNames', {'영점위치_z', 'PM_deg', 'wc', 'OS_퍼센트', 'Kv', '램프오차'})

% 읽는 법
%   - PM 24.5 -> 69.4 도로 계속 올라간다. 오버슈트 57.6 -> 3.5 %
%   - wc 는 20.8 -> 15.6 으로 조금 내려간다 (조금 느려진다)
%   - **그런데 Kv 가 329 -> 24.7 로 떨어진다.** 램프오차 0.003 -> 0.041
%   => 사양이 0.01 이었다면 z = 6 에서 벌써 0.01013 으로 턱걸이고,
%      z = 3 에서는 0.02 로 두 배가 되어 불합격이다.
%      계단응답만 보고 끌면 이것을 놓친다

figure;
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
plot(zv, pm8, 'o-', 'LineWidth', 2.5, 'MarkerSize', 8);
yline(50, 'r--', 'LineWidth', 1.5);
set(gca, 'XDir', 'reverse');
xlabel('영점 위치 z  (왼쪽으로 끄는 방향 ->)'); ylabel('PM [deg]');
title('왼쪽으로 끌면 PM 이 올라간다');

nexttile; hold on; grid on;
plot(zv, 1./kv8, 'o-', 'LineWidth', 2.5, 'MarkerSize', 8);
yline(0.01, 'r--', 'LineWidth', 1.5);
set(gca, 'XDir', 'reverse', 'YScale', 'log');
xlabel('영점 위치 z  (왼쪽으로 끄는 방향 ->)'); ylabel('램프오차');
title('그런데 정상상태오차는 나빠진다 (빨간 선이 사양)');

%% 4. 영점과 극점의 순서가 바뀌면 Lead 가 Lag 가 된다
%  앱에서 끌다 보면 영점이 극점을 지나쳐 버리는 일이 자주 생깁니다.
%  그 순간 제어기의 성질이 완전히 뒤집히는데, 화면 모양은 비슷해서 못 알아챕니다.

pr = {'영점 6.08 · 극점 45.9  (Lead)'; '영점 45.9 · 극점 6.08  (Lag)'};
zz = [6.078; 45.88];
pp = [45.88; 6.078];

ph9 = zeros(2,1); dc9 = zeros(2,1); hf9 = zeros(2,1);
wsc = logspace(-1, 3, 4001);

for k = 1:2
    Ck = (s + zz(k))/(s + pp(k));
    fr = squeeze(angle(freqresp(Ck, wsc)))*180/pi;
    if k == 1
        ph9(k) = max(fr);           % Lead 는 봉우리
    else
        ph9(k) = min(fr);           % Lag 는 골
    end
    dc9(k) = dcgain(Ck);
    hf9(k) = abs(evalfr(Ck, 1e5i));
end

table(pr, ph9, dc9, hf9, dc9./hf9, ...
    'VariableNames', {'배치', '위상_극값_deg', 'DC이득', '고주파이득', '비율'})

% 읽는 법
%   - 같은 두 숫자를 자리만 바꿨는데 위상이 +50 도와 -50 도로 뒤집힌다
%   - 비율 열이 alpha 와 1/alpha 로 정확히 뒤집혔다
%   => 앱에서 알아보는 법 : **위상 봉우리가 위로 솟았으면 Lead,
%      아래로 꺼졌으면 Lag.** 숫자를 읽을 필요가 없다

figure; hold on; grid on;
for k = 1:2
    Ck = (s + zz(k))/(s + pp(k));
    semilogx(wsc, squeeze(angle(freqresp(Ck, wsc)))*180/pi, 'LineWidth', 2.5);
end
set(gca, 'XScale', 'log');
yline(0, 'k--');
xlabel('주파수 [rad/s]'); ylabel('angle(C) [deg]');
legend(pr, 'Location', 'best');
title('봉우리면 Lead, 골이면 Lag');

%% 5. 사양을 앱에 그릴 "선" 으로 바꾼다
%  앱의 Design Requirements 는 사양을 화면에 선으로 그려 줍니다.
%  그런데 **몇 dB 에 그릴지는 우리가 계산해야** 합니다. 그 계산입니다.

ess_spec = 0.01;                % <-- 바꿔 보기 (램프오차 사양)
pm_spec = 50;                   % <-- 바꿔 보기 (위상여유 사양)

Kv_need = 1/ess_spec;

fprintf('\n[사양 -> 앱에 그릴 선]\n');
fprintf('  (1) 램프오차 %.3f 이하  =>  Kv >= %.0f\n', ess_spec, Kv_need);
fprintf('      저주파에서 |L| 은 Kv/w 보다 위에 있어야 한다. 즉 아래 선 위쪽\n');

w_lo = [0.1; 0.3; 1; 3];
table(w_lo, Kv_need./w_lo, 20*log10(Kv_need./w_lo), ...
    'VariableNames', {'w_rad_s', '필요한_크기', '필요한_크기_dB'})

fprintf('  (2) 위상여유 %.0f 도 이상  =>  보드 위상 창에 -%.0f 도 선을 긋는다\n', ...
    pm_spec, 180 - pm_spec);
fprintf('      교차주파수에서 위상 곡선이 그 선보다 위에 있으면 합격\n');
fprintf('  (3) 그 PM 이 대략 zeta = PM/100 = %.2f 이므로\n', pm_spec*0.01);
z_est = pm_spec*0.01;
fprintf('      오버슈트는 약 %.1f %% 로 예상된다 (계단응답 창의 한계선)\n', ...
    100*exp(-pi*z_est/sqrt(1 - z_est^2)));

% 읽는 법
%   - (1) 의 선은 기울기 -20 dB/dec 의 직선이다. 앱에서는 그 아래가 금지 구역
%   - (2) 는 수평선 하나. 아주 간단하다
%   - (3) 은 11A주차에서 배운 PM-zeta 관계를 쓴 것이다 (어림이다. 반드시 검산)

%% 6. Store 와 Compare 를 코드로 흉내내기
%  앱에서는 마음에 드는 설계를 Store 로 저장하고 Compare 로 겹쳐 봅니다.
%  코드에서는 그냥 셀 배열에 모아 두면 됩니다.

names = {'K = 100 만'; 'K + Lead 한 단'};
Cs = {100; 754.86*(s + 6.0783)/(s + 45.8829)};

pm6 = zeros(2,1); wc6 = zeros(2,1); os6 = zeros(2,1);
ts6 = zeros(2,1); wb6 = zeros(2,1); es6 = zeros(2,1);

for k = 1:2
    Lk = Cs{k}*G;
    [~, pm6(k), ~, wc6(k)] = margin(Lk);
    Tk = feedback(Lk, 1);
    si = stepinfo(Tk);
    os6(k) = si.Overshoot;
    ts6(k) = si.SettlingTime;
    wb6(k) = bandwidth(Tk);
    es6(k) = 1/dcgain(s*Lk);
end

table(names, pm6, wc6, wb6, os6, ts6, es6, ...
    'VariableNames', {'설계', 'PM_deg', 'wc', 'wb', 'OS_퍼센트', 'ts', '램프오차'})

figure; hold on; grid on;
t6 = (0:0.002:2)';
for k = 1:2
    plot(t6, step(feedback(Cs{k}*G, 1), t6), 'LineWidth', 2.5);
end
yline(1, 'k--');
xlabel('시간 [s]'); ylabel('출력 y');
legend(names, 'Location', 'southeast');
title('Compare — 같은 램프오차인데 과도응답이 전혀 다르다');

% 읽는 법
%   - 두 설계의 램프오차가 **똑같이 0.01** 이다. Lead 가 Kv 를 지켰다
%   - 그런데 PM 5.7 -> 53.5 도, 오버슈트 85 -> 23 %, ts 7.6 -> 0.44 초
%   => Lead 는 "정확도를 지키면서 과도응답만 고친" 것이다

%% 7. 앱이 보여 주지 않는 것 — 제어입력
%  앱의 기본 화면에는 제어입력 u 가 없습니다. 반드시 창을 추가해야 합니다
%  (New Plot -> Step -> r to u). 여기서는 직접 계산해 봅니다.
%
%  r 에서 u 까지의 전달함수는 u = C*e = C(r - y) 에서
%
%      U(s)/R(s) = C/(1 + C*G)
%
%  입니다. 계단 지령의 **맨 처음 값**이 가장 큽니다.

t7 = (0:1e-4:2)';
umax7 = zeros(2,1); u0_7 = zeros(2,1);

for k = 1:2
    Gu = minreal(Cs{k}/(1 + Cs{k}*G));
    uu = step(Gu, t7);
    umax7(k) = max(abs(uu));
    u0_7(k) = uu(1);
end

table(names, u0_7, umax7, [100; 754.86], ...
    'VariableNames', {'설계', 'u의_첫값', 'umax', '공식_K_over_alpha'})

% 읽는 법
%   - K 만 쓴 설계는 u 의 첫 값이 K = 100 이다
%   - Lead 를 넣은 설계는 **754.86 = K/alpha** 다. 7.5 배로 늘었다
%   - 공식과 실측이 정확히 같다. Lead 의 고주파 이득이 그대로 제어입력에 나온다
%   => 과도응답을 산 값이 제어입력이다. 모터가 12 V 짜리면 이 설계는 못 쓴다.
%      5번 스크립트(종합 설계) 에서 이 문제를 정면으로 다룬다

% 질문
%   - 3절에서 z 를 1 로 더 끌면 PM 과 램프오차가 어떻게 되나요
%     사양 두 개를 동시에 지키는 z 의 범위가 있나요
%   - 5절의 pm_spec 을 60 으로 올리면 (2) 의 선은 몇 도가 되나요
%   - 7절에서 umax 를 줄이려면 알파를 키워야 합니다 (= 위상을 덜 받는다).
%     그러면 PM 이 얼마나 떨어지는지 2번 스크립트의 5절 표로 확인해 보세요
