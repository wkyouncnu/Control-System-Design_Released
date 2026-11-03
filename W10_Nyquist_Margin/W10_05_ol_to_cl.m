%% W10_05_ol_to_cl.m
%  10주차 실습 (5) : 교수자 강의자료 06_FrequencyResponse 44~67쪽의 예제
%
%  이 스크립트에서 답할 질문
%    Q1. 개루프 L 만 보고 폐루프 T 를 어떻게 유추하는가?        -> 1절
%    Q2. 교차주파수와 대역폭은 각각 무엇이고 어떤 관계인가?      -> 2절
%    Q3. 폐루프 크기가 1 을 넘어 솟는 봉우리는 왜 생기는가?      -> 3절
%    Q4. 대역폭을 wn 과 zeta 로 쓰면 어떻게 되는가?             -> 4절
%    Q5. PM 이 커지면 zeta 가 커지고 %OS 가 줄어드는가?         -> 5절
%    Q6. zeta 하나를 정하면 나머지가 다 정해지는가?             -> 6절
%    Q7. 개루프를 빠르게 하면 폐루프도 정말 빨라지는가?          -> 7절
%
%  대응하는 강의노트 : W10_LectureNote.mlx 의
%    4-2 / 4-3 / 5-1-1 / 5-1-2 / 5-1-3 / 5-1-4 / 5-1-5 절
%
%  이 스크립트는 공통 함수(dg_*, plant_*)를 쓰지 않습니다.
%  MATLAB 기본 명령만으로 적어서, 절마다 따로 떼어 실행할 수 있습니다.
%
%  제어시스템설계 10주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 1. 개루프 L 에서 폐루프 T 를 유추한다  (강의자료 44~47쪽)
%  T = L/(1+L) 한 줄에서 두 가지 극단만 본다.
%    |L| >> 1 (저주파) -> 분모의 1 을 무시 -> T = L/L = 1
%    |L| << 1 (고주파) -> 분모의 L 을 무시 -> T = L/1 = L
%  강의자료의 문장 그대로 : L = 100 이면 T = 100/101 = 0.99 (거의 1)

% (1) 식 한 줄로 확인한다. ratio 열이 고주파에서 1, 저주파에서 0 이 된다
L_one = [0.001; 0.01; 0.1; 1; 10; 100; 1000];
T_one = L_one ./ (1 + L_one);             % T = L/(1+L)
ratio_one = T_one ./ L_one;               % T 가 L 의 몇 배인가
table(L_one, T_one, ratio_one)

% (2) 가장 단순한 L(s) = 1/s 로 두 근사가 실제로 성립하는지 본다
s   = tf('s');
L_s = 1/s;                                % 적분기 하나. 교차주파수가 정확히 1
T_s = feedback(L_s, 1);                   % T = 1/(s+1)

w_one  = logspace(-2, 2, 800);
magL_1 = 20*log10(squeeze(abs(freqresp(L_s, w_one))));
magT_1 = 20*log10(squeeze(abs(freqresp(T_s, w_one))));

% 교차주파수에서 두 곡선의 차이가 약 3 dB 인지
gap_at_wc = interp1(w_one, magL_1, 1) - interp1(w_one, magT_1, 1)

figure('Name','1절: L 에서 T 를 유추', 'Position', [60 60 980 380]);

subplot(1,2,1);
semilogx(w_one, magL_1, 'LineWidth', 2.4); hold on; grid on;
semilogx(w_one, magT_1, '--', 'LineWidth', 2.4);
yline(0, 'k:');  xline(1, 'k:');
ylim([-45 45]);
xlabel('\omega [rad/s]'); ylabel('크기 [dB]');
legend('개루프 |L|', '폐루프 |T|', 'Location', 'southwest');
title('\omega<1 에서 T 는 0 dB, \omega>1 에서 T 는 L 과 겹친다');

subplot(1,2,2);
loglog(L_one, T_one, 'o-', 'LineWidth', 2, 'MarkerSize', 8); hold on; grid on;
loglog(L_one, L_one, 'k:', 'LineWidth', 1.6);
yline(1, 'r--', 'LineWidth', 1.4);
xlabel('개루프 값 L'); ylabel('T = L/(1+L)');
legend('T', 'T = L 기준선', 'T = 1 기준선', 'Location', 'southeast');
title('왼쪽 끝은 T \approx L, 오른쪽 끝은 T \approx 1');

%% 2. 교차주파수와 대역폭  (강의자료 48~49, 62~63쪽)
%  wc  : 개루프 |L| 이 0 dB 가 되는 주파수       -> margin 으로 잰다
%  wBW : 폐루프 |T| 가 -3 dB 가 되는 주파수      -> bandwidth 로 잰다
%  어림 : wc <= wBW <= 2*wc  (개루프만 보고 폐루프 빠르기를 가둘 수 있다)

s   = tf('s');
G_2 = (0.5*s + 1.3) / (s^3 + 1.2*s^2 + 1.6*s);
T_2 = feedback(G_2, 1);

[~, ~, ~, wc_2] = margin(G_2);            % 개루프 0 dB 교차주파수
wbw_2 = bandwidth(T_2);                   % 폐루프 -3 dB 주파수
ratio_2 = wbw_2 / wc_2                    % 1 과 2 사이여야 한다

in_bound = (ratio_2 >= 1) && (ratio_2 <= 2)

% -3 dB 의 정체 : 크기 1/sqrt(2), 전력은 그 제곱이므로 절반
minus3 = 20*log10(1/sqrt(2))
half_power = (1/sqrt(2))^2

% 이득을 아주 작게 하면 개루프와 폐루프가 구별되지 않는다
K_small = 0.001;
G_sm = K_small * G_2;
T_sm = feedback(G_sm, 1);

w_2    = logspace(-2, 2, 900);
magL_2 = 20*log10(squeeze(abs(freqresp(G_2, w_2))));
magT_2 = 20*log10(squeeze(abs(freqresp(T_2, w_2))));
magL_s = 20*log10(squeeze(abs(freqresp(G_sm, w_2))));
magT_s = 20*log10(squeeze(abs(freqresp(T_sm, w_2))));

max_gap_small = max(abs(magL_s - magT_s))  % 거의 0 이다

figure('Name','2절: 교차주파수와 대역폭', 'Position', [60 60 980 380]);

subplot(1,2,1);
semilogx(w_2, magL_2, 'LineWidth', 2); hold on; grid on;
semilogx(w_2, magT_2, 'LineWidth', 2);
yline(0,  'k--', 'LineWidth', 1.4);
yline(-3, 'r:',  'LineWidth', 1.4);
plot(wc_2,  0,  'o', 'MarkerSize', 10, 'LineWidth', 2);
plot(wbw_2, -3, 's', 'MarkerSize', 10, 'LineWidth', 2);
ylim([-45 35]);
xlabel('\omega [rad/s]'); ylabel('크기 [dB]');
legend('개루프 |L|', '폐루프 |T|', 'Location', 'southwest');
title(sprintf('\\omega_c = %.2f, \\omega_{BW} = %.2f (비 %.2f)', ...
      wc_2, wbw_2, ratio_2));

subplot(1,2,2);
semilogx(w_2, magL_s, 'LineWidth', 3); hold on; grid on;
semilogx(w_2, magT_s, '--', 'LineWidth', 1.8);
xlabel('\omega [rad/s]'); ylabel('크기 [dB]');
legend('개루프 |L|', '폐루프 |T|', 'Location', 'southwest');
title(sprintf('K = %g : 두 곡선 차이 최대 %.1e dB', K_small, max_gap_small));

%% 3. 공진 봉우리 Mr 와 감쇠비  (강의자료 50~53, 65~66쪽)
%  유도한 공식    Mr = 1/(2*zeta*sqrt(1-zeta^2))
%                 wr = wn*sqrt(1-2*zeta^2)
%  zeta >= 0.707 이면 제곱근 안이 음수가 되어 봉우리가 생기지 않는다.

zeta_3 = [0.1; 0.2; 0.4; 0.707];
Mr_formula  = zeros(4,1);
Mr_measured = zeros(4,1);
wr_formula  = zeros(4,1);
for i = 1:4
    z  = zeta_3(i);
    T3 = tf(1, [1, 2*z, 1]);               % wn = 1 인 2차 표준형
    Mr_formula(i)  = 1/(2*z*sqrt(1 - z^2));
    Mr_measured(i) = max(abs(squeeze(freqresp(T3, logspace(-1, 1, 2000)))));
    wr_formula(i)  = sqrt(1 - 2*z^2);      % 음수면 실수 해가 없다는 뜻
end
table(zeta_3, Mr_formula, Mr_measured, wr_formula)

% 봉우리가 사라지는 경계를 손으로 확인한다
zeta_edge = 1/sqrt(2)
inside_at_edge = 1 - 2*zeta_edge^2        % 정확히 0

figure('Name','3절: 공진 봉우리', 'Position', [60 60 980 380]);

subplot(1,2,1);
w_3 = logspace(-1, 1, 1200);
hold on; grid on; set(gca, 'XScale', 'log');
for i = 1:4
    T3 = tf(1, [1, 2*zeta_3(i), 1]);
    semilogx(w_3, 20*log10(squeeze(abs(freqresp(T3, w_3)))), 'LineWidth', 2);
end
yline(0, 'k--');
ylim([-30 20]);
xlabel('\omega / \omega_n'); ylabel('|T| [dB]');
legend('\zeta = 0.1', '\zeta = 0.2', '\zeta = 0.4', '\zeta = 0.707', ...
       'Location', 'southwest');
title('\zeta 가 작을수록 봉우리가 높다');

subplot(1,2,2);
z_fine = linspace(0.05, 0.705, 400);
plot(z_fine, 1./(2*z_fine.*sqrt(1 - z_fine.^2)), 'LineWidth', 2); hold on; grid on;
plot(zeta_3, Mr_measured, 'o', 'MarkerSize', 9, 'LineWidth', 2);
xline(1/sqrt(2), 'k:', 'LineWidth', 1.6);
yline(1.3, 'r--');
ylim([0 6]);
xlabel('\zeta'); ylabel('M_r');
legend('공식', '실측', '\zeta = 0.707', '설계 기준 1.3', 'Location', 'northeast');
title('\zeta = 0.707 위에서는 정의되지 않는다');

%% 4. 대역폭을 wn 과 zeta 로 쓰면  (강의자료 54~56쪽)
%  유도 결과
%    wBW = wn * sqrt( 1 - 2*zeta^2 + sqrt(4*zeta^4 - 4*zeta^2 + 2) )
%  읽을 것 두 가지
%    wn 이 앞에 곱으로 있다          -> 대역폭은 wn 에 비례
%    제곱근 안은 zeta 만의 함수이고 감소 -> zeta 가 커지면 대역폭은 줄어든다

zeta_4 = [0.1; 0.3; 0.5; 0.707; 0.9];
bw_formula  = sqrt(1 - 2*zeta_4.^2 + sqrt(4*zeta_4.^4 - 4*zeta_4.^2 + 2));  % wn = 1
bw_measured = zeros(5,1);
for i = 1:5
    bw_measured(i) = bandwidth(tf(1, [1, 2*zeta_4(i), 1]));
end
err_4 = bw_formula - bw_measured;
table(zeta_4, bw_formula, bw_measured, err_4)

% zeta = 0.707 에서 대역폭이 거의 wn 과 같다 — 외워 두면 편한 자리
bw_at_707 = bw_formula(4)

% 시간영역 세 사양이 대역폭에 반비례하는 것을 로그-로그로 본다
bw_axis = logspace(-0.5, 1.5, 200);
tr_rule = 1.8 ./ bw_axis;                 % tr = 1.8/wBW

figure('Name','4절: 대역폭 공식', 'Position', [60 60 980 380]);

subplot(1,2,1);
z_f = linspace(0.05, 1.2, 400);
plot(z_f, sqrt(1 - 2*z_f.^2 + sqrt(4*z_f.^4 - 4*z_f.^2 + 2)), 'LineWidth', 2);
hold on; grid on;
plot(zeta_4, bw_measured, 'o', 'MarkerSize', 9, 'LineWidth', 2);
yline(1, 'k:');  xline(1/sqrt(2), 'k:');
xlabel('\zeta'); ylabel('\omega_{BW} / \omega_n');
legend('공식', '실측 (bandwidth)', 'Location', 'southwest');
title('\zeta 가 커지면 대역폭은 줄어든다');

subplot(1,2,2);
loglog(bw_axis, tr_rule, 'LineWidth', 2); hold on; grid on;
loglog(bw_axis, 4.0 ./ bw_axis, '--', 'LineWidth', 2);
loglog(bw_axis, 3.1 ./ bw_axis, ':',  'LineWidth', 2.4);
xlabel('\omega_{BW} [rad/s]'); ylabel('시간 [s]');
legend('t_r \approx 1.8/\omega_{BW}', 't_s 비례선', 'T_p 비례선', ...
       'Location', 'southwest');
title('기울기 -1 : 대역폭 두 배면 시간 절반');

%% 5. 위상여유와 감쇠비, 그리고 오버슈트  (강의자료 57~60쪽)
%  정확한 식 (2차 표준형에서 유도)
%    wc/wn = sqrt( sqrt(1+4*zeta^4) - 2*zeta^2 )
%    PM    = atan( 2*zeta / (wc/wn) )
%  어림식 : zeta = PM/100  (zeta 가 0.6 이하에서만 잘 맞는다)
%  그리고 %OS = 100*exp(-pi*zeta/sqrt(1-zeta^2))  (4주차 공식)

zeta_5 = [0.2; 0.3; 0.5; 0.7; 0.9];
u_5      = sqrt(sqrt(1 + 4*zeta_5.^4) - 2*zeta_5.^2);     % wc/wn
PM_exact = atan2(2*zeta_5, u_5) * 180/pi;                 % 정확한 PM [도]
PM_rule  = 100 * zeta_5;                                  % 어림식
OS_pct   = 100 * exp(-pi*zeta_5 ./ sqrt(1 - zeta_5.^2));  % 오버슈트 [%]
PM_gap   = PM_rule - PM_exact;
table(zeta_5, PM_exact, PM_rule, PM_gap, OS_pct)

% 손으로 한 번 넣어 본다 : zeta = 0.5
z_hand  = 0.5;
u_hand  = sqrt(sqrt(1 + 4*z_hand^4) - 2*z_hand^2)         % 0.7862
PM_hand = atan2(2*z_hand, u_hand) * 180/pi                % 51.83 도
PM_hand_rule = 100 * z_hand                               % 어림은 50 도

% PM 이 커질 때 OS 가 정말 줄어드는지 — 실제 2차 폐루프로 확인한다
OS_meas = zeros(5,1);
for i = 1:5
    OS_meas(i) = stepinfo(tf(1, [1, 2*zeta_5(i), 1])).Overshoot;
end
table(zeta_5, PM_exact, OS_pct, OS_meas)

figure('Name','5절: PM 과 zeta 와 오버슈트', 'Position', [60 60 980 380]);

subplot(1,2,1);
z_f5 = linspace(0.05, 1.0, 400);
u_f5 = sqrt(sqrt(1 + 4*z_f5.^4) - 2*z_f5.^2);
plot(z_f5, atan2(2*z_f5, u_f5)*180/pi, 'LineWidth', 2); hold on; grid on;
plot(z_f5, 100*z_f5, 'r--', 'LineWidth', 1.8);
xline(0.6, 'k:', 'LineWidth', 1.6);
ylim([0 100]);
xlabel('\zeta'); ylabel('위상여유 [도]');
legend('정확한 식', '어림식 100\zeta', '\zeta = 0.6', 'Location', 'southeast');
title('\zeta \leq 0.6 에서는 어림을 써도 좋다');

subplot(1,2,2);
plot(atan2(2*z_f5, u_f5)*180/pi, 100*exp(-pi*z_f5./sqrt(1 - z_f5.^2)), ...
     'LineWidth', 2); hold on; grid on;
plot(PM_exact, OS_meas, 'o', 'MarkerSize', 9, 'LineWidth', 2);
xline(45, 'k:');  xline(60, 'k:');
xlabel('위상여유 [도]'); ylabel('오버슈트 [%]');
legend('공식', '실측 (stepinfo)', 'Location', 'northeast');
title('PM 이 커지면 오버슈트가 줄어든다');

%% 6. zeta 하나로 네 숫자가 전부 정해진다  (강의자료 61쪽 세 화살표)
%  주파수영역에서 읽는 값 세 개 (PM, wBW, Mr) 가 모두 zeta 를 거쳐
%  시간영역(오버슈트, 상승시간) 으로 번역된다. zeta 가 두 세계를 잇는 다리다.

zeta_6 = 0.5;                                               % 하나만 정한다

u_6  = sqrt(sqrt(1 + 4*zeta_6^4) - 2*zeta_6^2);
PM_6 = atan2(2*zeta_6, u_6) * 180/pi                        % ① 위상여유 [도]
bw_6 = sqrt(1 - 2*zeta_6^2 + sqrt(4*zeta_6^4 - 4*zeta_6^2 + 2))  % ② 대역폭 (wn=1)
Mr_6 = 1/(2*zeta_6*sqrt(1 - zeta_6^2))                      % ③ 공진봉우리
OS_6 = 100*exp(-pi*zeta_6/sqrt(1 - zeta_6^2))               % 시간영역 오버슈트 [%]

% 거꾸로도 된다 : 측정한 PM 에서 zeta 를 되찾아 오버슈트를 짐작한다
PM_measured = PM_6;
zeta_back   = PM_measured / 100                             % 어림식으로 역산
OS_back     = 100*exp(-pi*zeta_back/sqrt(1 - zeta_back^2))  % 짐작한 오버슈트

% 세 숫자를 실제 2차 폐루프에서 재어 대조한다
T_6  = tf(1, [1, 2*zeta_6, 1]);                             % wn = 1
[~, pm_chk] = margin(1/(tf('s')*(tf('s') + 2*zeta_6)));     % L = 1/(s(s+2*zeta))
bw_chk  = bandwidth(T_6);
Mr_chk  = max(abs(squeeze(freqresp(T_6, logspace(-1, 1, 2000)))));
OS_chk  = stepinfo(T_6).Overshoot;

quantity = ["PM [도]"; "wBW"; "Mr"; "OS [%]"];
formula  = [PM_6; bw_6; Mr_6; OS_6];
measured = [pm_chk; bw_chk; Mr_chk; OS_chk];
table(quantity, formula, measured)

figure('Name','6절: zeta 가 두 세계를 잇는다', 'Position', [60 60 980 380]);

subplot(1,2,1);
w_6 = logspace(-1, 1, 1000);
semilogx(w_6, 20*log10(squeeze(abs(freqresp(T_6, w_6)))), 'LineWidth', 2);
hold on; grid on;
yline(0, 'k--');  yline(-3, 'r:');
plot(bw_chk, -3, 's', 'MarkerSize', 10, 'LineWidth', 2);
yline(20*log10(Mr_chk), 'k:');
xlabel('\omega / \omega_n'); ylabel('|T| [dB]');
title(sprintf('주파수영역 : M_r = %.3f, \\omega_{BW} = %.3f', Mr_chk, bw_chk));

subplot(1,2,2);
t_6 = (0:0.02:20)';
plot(t_6, step(T_6, t_6), 'LineWidth', 2); hold on; grid on;
yline(1, 'k--');
yline(1 + OS_chk/100, 'r:', 'LineWidth', 1.4);
xlabel('시간 [s]'); ylabel('출력');
title(sprintf('시간영역 : %%OS = %.2f %% (공식 %.2f %%)', OS_chk, OS_6));

%% 7. 개루프를 빠르게 하면 폐루프도 빨라진다  (강의자료 64쪽)
%  가장 깨끗한 예 : zeta 를 고정하고 wn 만 키운다.
%    wBW 는 wn 에 비례해서 커진다
%    tr  은 같은 비율로 줄어든다
%    %OS 는 세 경우가 전부 같다 (오버슈트는 zeta 만 정한다)
%  빠르기와 출렁임은 서로 다른 다이얼이다.

zeta_7 = 0.2;
wn_7   = [1; sqrt(10); 10];

bw_7 = zeros(3,1);  tr_7 = zeros(3,1);  os_7 = zeros(3,1);  ts_7 = zeros(3,1);
for i = 1:3
    w  = wn_7(i);
    T7 = tf(w^2, [1, 2*zeta_7*w, w^2]);        % 2차 표준형 폐루프
    bw_7(i) = bandwidth(T7);
    info    = stepinfo(T7);
    tr_7(i) = info.RiseTime;
    ts_7(i) = info.SettlingTime;
    os_7(i) = info.Overshoot;
end
table(wn_7, bw_7, tr_7, ts_7, os_7)

% 비율로 보면 더 분명하다 — 셋째 줄은 전부 1 이 나온다
bw_ratio = bw_7 / bw_7(1);
tr_ratio = tr_7(1) ./ tr_7;                    % 거꾸로 잡아야 같은 수가 된다
os_ratio = os_7 / os_7(1);
table(wn_7, bw_ratio, tr_ratio, os_ratio)

% 눈대중 식과도 맞는지
tr_rule_7 = 1.8 ./ bw_7;
table(wn_7, bw_7, tr_7, tr_rule_7)

figure('Name','7절: wn 만 키우면', 'Position', [60 60 980 380]);

subplot(1,2,1);
t_7 = (0:0.005:20)';
hold on; grid on;
for i = 1:3
    T7 = tf(wn_7(i)^2, [1, 2*zeta_7*wn_7(i), wn_7(i)^2]);
    plot(t_7, step(T7, t_7), 'LineWidth', 2);
end
yline(1, 'k--');
xlim([0 20]);
xlabel('시간 [s]'); ylabel('출력');
legend('\omega_n = 1', '\omega_n = 3.16', '\omega_n = 10', 'Location', 'southeast');
title(sprintf('오버슈트는 세 경우 모두 %.1f %%', os_7(1)));

subplot(1,2,2);
w_7 = logspace(-1, 2.5, 1200);
hold on; grid on; set(gca, 'XScale', 'log');
for i = 1:3
    T7 = tf(wn_7(i)^2, [1, 2*zeta_7*wn_7(i), wn_7(i)^2]);
    semilogx(w_7, 20*log10(squeeze(abs(freqresp(T7, w_7)))), 'LineWidth', 2);
    plot(bw_7(i), -3, 's', 'MarkerSize', 10, 'LineWidth', 2);
end
yline(-3, 'r:');
ylim([-40 20]);
xlabel('\omega [rad/s]'); ylabel('|T| [dB]');
title('모양은 같고 좌우로만 이동한다');

%% 8. 이번 실습의 정리
%  - T = L/(1+L) 에서 저주파는 T = 1, 고주파는 T = L.
%    그래서 개루프만 봐도 폐루프를 안다. L = 100 이면 T = 100/101 = 0.99
%  - 근사가 통하지 않는 곳은 |L| = 1 근처뿐이다.
%    바로 거기의 위상이 PM 이고, 그래서 PM 을 보는 것이다
%  - wc 는 개루프 0 dB, wBW 는 폐루프 -3 dB. 서로 다른 주파수지만
%    wc <= wBW <= 2*wc 로 묶여 있다 (이 예에서 비가 1.59)
%  - Mr = 1/(2*zeta*sqrt(1-zeta^2)). zeta >= 0.707 이면 봉우리가 아예 없다
%  - 대역폭은 wn 에 비례하고 zeta 가 커지면 줄어든다.
%    zeta = 0.707 에서 wBW 가 거의 wn 과 같다
%  - PM 이 커지면 zeta 가 커지고 %OS 가 줄어든다. 어림식 zeta = PM/100 은
%    zeta 가 0.6 이하에서만 믿을 만하다 (0.9 에서는 15 도나 빗나간다)
%  - zeta 하나를 정하면 PM, wBW, Mr, %OS 가 전부 따라 정해진다
%  - 빠르기(wn, 대역폭) 와 출렁임(zeta) 은 서로 다른 다이얼이다.
%    이득 K 로 빠르게 하면 PM 이 깎여 둘이 함께 움직인다 (6절 W10_06 참고)
