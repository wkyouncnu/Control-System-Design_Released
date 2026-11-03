%% W10_06_margin_design.m
%  10주차 실습 (6) : 교수자 강의자료 06_FrequencyResponse 68~72쪽의 예제
%
%  이 스크립트에서 답할 질문
%    Q1. 플랜트 하나를 받으면 어떤 순서로 분석하는가?        -> 1절
%    Q2. 위상여유만 보고 오버슈트를 맞출 수 있는가?          -> 2절
%    Q3. 이득 K 를 바꾸면 여유와 응답이 어떻게 맞바뀌는가?    -> 3절
%
%  대응하는 강의노트 : W10_LectureNote.mlx 의 6-3 절
%
%  이 스크립트는 공통 함수(dg_*, plant_*)를 쓰지 않습니다.
%  MATLAB 기본 명령만으로 적어서, 절마다 따로 떼어 실행할 수 있습니다.
%
%  이 절들의 플랜트는 강의자료와 같은 것 하나뿐입니다.
%    G(s) = (0.5s + 1.3) / ( s^3 + 1.2s^2 + 1.6s )
%         = (0.5s + 1.3) / ( s*(s^2 + 1.2s + 1.6) )
%  분모에 s 가 하나 있으므로 적분기가 하나 들어 있고,
%  남은 2차 부분은 wn = sqrt(1.6) = 1.2649, zeta = 0.6/wn = 0.4743 이다.
%  분자의 영점은 0.5s + 1.3 = 0 에서 s = -2.6 이다.
%
%  제어시스템설계 10주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 1. 플랜트 하나를 일곱 걸음으로 분석한다  (강의자료 68~69쪽)
%  걸음 (1) 플랜트를 적는다        (2) 구조를 손으로 읽는다
%        (3) 폐루프를 만든다        (4) 극점을 본다
%        (5) 근궤적으로 길을 본다   (6) 보드 선도와 여유를 읽는다
%        (7) 계단응답을 재어 대조한다

% (1) 플랜트
G_1 = tf([0.5 1.3], [1 1.2 1.6 0])

% (2) 구조를 손으로 읽는다 — 분모를 s*(s^2 + 1.2s + 1.6) 로 본다
wn_1    = sqrt(1.6)                % 1.2649
zeta_1  = 1.2/(2*wn_1)             % 0.4743
zero_1  = -1.3/0.5                 % -2.6  (분자의 영점)
pole_G1 = pole(G_1)                % 0 과 복소 극점 한 쌍

% (3) 폐루프 (K = 1, 단위 피드백)
K_1 = 1;
T_1 = feedback(K_1*G_1, 1)

% (4) 폐루프 극점 — 전부 왼쪽에 있는지
pole_T1 = pole(T_1)
maxRe_1 = max(real(pole_T1))       % 음수면 안정

% (6) 보드 선도의 여유 — 네 숫자를 한 번에 받는다
[gm_1, pm_1, wcg_1, wcp_1] = margin(K_1*G_1);
gm_dB_1 = 20*log10(gm_1);
quantity_1 = ["GM (배)"; "GM (dB)"; "PM (도)"; "wcg (위상교차)"; "wcp (이득교차)"];
value_1    = [gm_1; gm_dB_1; pm_1; wcg_1; wcp_1];
table(quantity_1, value_1)

% (7) 계단응답을 재어 대조한다
info_1 = stepinfo(T_1);
spec_1 = ["상승시간 tr [s]"; "정착시간 ts [s]"; "오버슈트 [%]"; "첨두시각 Tp [s]"];
meas_1 = [info_1.RiseTime; info_1.SettlingTime; info_1.Overshoot; info_1.PeakTime];
table(spec_1, meas_1)

% (5) 와 (6) 과 (7) 을 한 그림에 — 같은 플랜트를 세 눈으로 본다
figure('Name','1절: 일곱 걸음', 'Position', [60 60 1020 620]);

subplot(2,2,1);                               % (5) 근궤적
rlocus(G_1); hold on; grid on;
plot(real(pole_T1), imag(pole_T1), 'rs', 'MarkerSize', 10, 'LineWidth', 2);
title('(5) 근궤적과 K = 1 의 폐루프 극점');

subplot(2,2,2);                               % (6) 크기 선도
w_1    = logspace(-2, 2, 1200);
mag_1  = 20*log10(squeeze(abs(freqresp(K_1*G_1, w_1))));
semilogx(w_1, mag_1, 'LineWidth', 2); hold on; grid on;
yline(0, 'k--');
plot(wcp_1, 0, 'o', 'MarkerSize', 10, 'LineWidth', 2);
plot([wcg_1 wcg_1], [-gm_dB_1 0], 'r-', 'LineWidth', 4);
ylim([-50 40]);
xlabel('\omega [rad/s]'); ylabel('|KG| [dB]');
title(sprintf('(6) GM = %.2f dB (\\omega_{cg} = %.3f)', gm_dB_1, wcg_1));

subplot(2,2,4);                               % (6) 위상 선도
ph_1 = rad2deg(unwrap(angle(squeeze(freqresp(K_1*G_1, w_1)))));
semilogx(w_1, ph_1, 'LineWidth', 2); hold on; grid on;
yline(-180, 'r--');
ph_at_wcp_1 = interp1(w_1, ph_1, wcp_1);
plot([wcp_1 wcp_1], [-180 ph_at_wcp_1], 'r-', 'LineWidth', 4);
xlabel('\omega [rad/s]'); ylabel('\angle KG [도]');
title(sprintf('PM = %.2f 도 (\\omega_{cp} = %.3f)', pm_1, wcp_1));

subplot(2,2,3);                               % (7) 계단응답
t_1 = (0:0.02:30)';
plot(t_1, step(T_1, t_1), 'LineWidth', 2); hold on; grid on;
yline(1, 'k--');
yline(1 + info_1.Overshoot/100, 'r:', 'LineWidth', 1.4);
xlabel('시간 [s]'); ylabel('출력');
title(sprintf('(7) %%OS = %.2f %%, t_s = %.2f s', ...
      info_1.Overshoot, info_1.SettlingTime));

%% 2. 위상여유에서 오버슈트를 짐작한다  (강의자료 70쪽)
%  강의자료의 두 줄을 그대로 쓴다.
%    zeta = PM * 0.01                                   (어림식)
%    %OS  = exp( -zeta*pi/sqrt(1-zeta^2) ) * 100        (4주차 공식)
%  주파수영역에서 읽은 한 숫자(PM) 로 시간영역을 짐작하는 것이다.

G_2 = tf([0.5 1.3], [1 1.2 1.6 0]);
K_2 = 1;
T_2 = feedback(K_2*G_2, 1);

[~, pm_2] = margin(K_2*G_2);
pm_2                                           % 44.6703 도

zeta_2 = pm_2 * 0.01                           % 0.4467  <- 어림식
OS_predicted = exp(-((zeta_2*pi)/sqrt(1 - zeta_2^2))) * 100   % 20.83 %

OS_measured = stepinfo(T_2).Overshoot          % 20.77 %  <- 실측
OS_error    = OS_predicted - OS_measured       % 거의 0

% 2차 부분의 실제 감쇠비와 비교한다 — 어림식이 무엇을 맞춘 셈인지
zeta_plant = 1.2/(2*sqrt(1.6))                 % 0.4743 (영점·적분기 빼고 본 값)

% 거꾸로 쓰는 법 : 오버슈트 목표에서 필요한 PM 을 역산한다
OS_target   = 10;                                                   % 목표 10 %
zeta_need   = -log(OS_target/100) / sqrt(pi^2 + log(OS_target/100)^2)
PM_need     = zeta_need * 100                                       % 필요한 PM [도]

figure('Name','2절: PM 에서 오버슈트', 'Position', [60 60 980 380]);

subplot(1,2,1);
pm_axis   = linspace(5, 80, 300);
zeta_axis = pm_axis * 0.01;
plot(pm_axis, exp(-((zeta_axis*pi)./sqrt(1 - zeta_axis.^2)))*100, 'LineWidth', 2);
hold on; grid on;
plot(pm_2, OS_measured, 'rp', 'MarkerSize', 16, 'MarkerFaceColor', 'r');
xline(PM_need, 'k:', 'LineWidth', 1.6);
yline(OS_target, 'k:', 'LineWidth', 1.6);
xlabel('위상여유 [도]'); ylabel('오버슈트 [%]');
legend('어림식 곡선', '이번 플랜트 실측', 'Location', 'northeast');
title(sprintf('PM %.1f 도 \\rightarrow %%OS %.1f %%', pm_2, OS_measured));

subplot(1,2,2);
t_2 = (0:0.02:30)';
plot(t_2, step(T_2, t_2), 'LineWidth', 2); hold on; grid on;
yline(1, 'k--');
yline(1 + OS_predicted/100, 'r:',  'LineWidth', 1.6);
yline(1 + OS_measured/100,  'b-.', 'LineWidth', 1.2);
xlabel('시간 [s]'); ylabel('출력');
legend('계단응답', sprintf('예측 %.2f %%', OS_predicted), ...
       sprintf('실측 %.2f %%', OS_measured), 'Location', 'southeast');
title('두 선이 거의 겹친다');

%% 3. 이득 K 로 여유와 속도를 맞바꾼다  (강의자료 71~72쪽)
%  K 를 키우면
%    크기 선도가 위로 평행이동   -> wcp 가 오른쪽으로 -> 빨라진다
%    위상 선도는 그대로          -> wcp 에서 읽히는 각이 줄어든다 -> PM 감소
%    GM 도 같은 dB 만큼 줄어든다
%  즉 "빠르게" 와 "안정하게" 는 K 하나로는 동시에 못 얻는다.

G_3 = tf([0.5 1.3], [1 1.2 1.6 0]);
K_3 = [0.7; 1; 1.2];

gm_dB_3 = zeros(3,1);  pm_3 = zeros(3,1);
wcp_3   = zeros(3,1);  wcg_3 = zeros(3,1);
tr_3    = zeros(3,1);  ts_3  = zeros(3,1);  os_3 = zeros(3,1);
os_pred_3 = zeros(3,1);
for i = 1:3
    Li = K_3(i) * G_3;
    [g, p, wg, wp] = margin(Li);
    gm_dB_3(i) = 20*log10(g);
    pm_3(i)    = p;
    wcg_3(i)   = wg;
    wcp_3(i)   = wp;

    Ti   = feedback(Li, 1);
    info = stepinfo(Ti);
    tr_3(i) = info.RiseTime;
    ts_3(i) = info.SettlingTime;
    os_3(i) = info.Overshoot;

    z = p * 0.01;                                      % 2절의 어림식
    os_pred_3(i) = exp(-((z*pi)/sqrt(1 - z^2))) * 100;
end

% 여유 쪽 표
table(K_3, gm_dB_3, pm_3, wcp_3, wcg_3)

% 응답 쪽 표
table(K_3, tr_3, ts_3, os_3, os_pred_3)

% K 가 평행이동이라는 것을 숫자로 확인한다
shift_dB_3 = 20*log10(K_3 / K_3(1))                % 0, 3.10, 4.68 dB
gm_drop_3  = gm_dB_3(1) - gm_dB_3                  % 똑같이 줄어든다
wcg_spread = max(wcg_3) - min(wcg_3)               % 0 — 위상교차는 안 움직인다

% 정착시간만 반대로 간다 — 빨리 올라가지만 오래 출렁인다
table(K_3, tr_3, ts_3)

figure('Name','3절: K = 0.7 / 1 / 1.2', 'Position', [60 60 1020 620]);

w_3 = logspace(-2, 2, 1200);
mag_base_3 = 20*log10(squeeze(abs(freqresp(G_3, w_3))));
ph_base_3  = rad2deg(unwrap(angle(squeeze(freqresp(G_3, w_3)))));

subplot(2,2,1);                                    % 크기 : 평행이동
hold on; grid on; set(gca, 'XScale', 'log');
for i = 1:3
    semilogx(w_3, 20*log10(K_3(i)) + mag_base_3, 'LineWidth', 2);
    plot(wcp_3(i), 0, 'o', 'MarkerSize', 9, 'LineWidth', 2);
end
yline(0, 'k--');
ylim([-45 35]);
xlabel('\omega [rad/s]'); ylabel('|KG| [dB]');
legend('K = 0.7', '', 'K = 1', '', 'K = 1.2', '', 'Location', 'southwest');
title('크기 : 위로 올라가며 \omega_{cp} 가 커진다');

subplot(2,2,3);                                    % 위상 : 하나뿐
semilogx(w_3, ph_base_3, 'LineWidth', 2); hold on; grid on;
yline(-180, 'r--');
for i = 1:3
    plot(wcp_3(i), interp1(w_3, ph_base_3, wcp_3(i)), ...
         'o', 'MarkerSize', 9, 'LineWidth', 2);
end
xlabel('\omega [rad/s]'); ylabel('\angle KG [도]');
title('위상 : 세 경우가 같은 곡선. 읽는 자리만 옮겨간다');

subplot(2,2,2);                                    % 여유 두 개
bar([gm_dB_3 pm_3]); grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', {'K = 0.7','K = 1','K = 1.2'});
ylabel('여유');
legend('GM [dB]', 'PM [도]', 'Location', 'northeast');
ylim([0 80]);
title('K 가 커지면 두 여유가 함께 줄어든다');

subplot(2,2,4);                                    % 계단응답
t_3 = (0:0.02:25)';
hold on; grid on;
for i = 1:3
    plot(t_3, step(feedback(K_3(i)*G_3, 1), t_3), 'LineWidth', 2);
end
yline(1, 'k--');
ylim([0 1.45]);
xlabel('시간 [s]'); ylabel('출력');
legend(sprintf('K = 0.7 : %%OS %.1f', os_3(1)), ...
       sprintf('K = 1 : %%OS %.1f',   os_3(2)), ...
       sprintf('K = 1.2 : %%OS %.1f', os_3(3)), 'Location', 'southeast');
title('빨라지는 대신 더 출렁인다');

%% 4. 이번 실습의 정리
%  - 플랜트를 받으면 순서가 있다 : 식 -> 구조 읽기 -> 폐루프 -> 극점
%    -> 근궤적 -> 보드 여유 -> 계단응답 대조. 마지막 대조를 빠뜨리지 않는다
%  - 이 플랜트는 적분기 하나 + (wn = 1.2649, zeta = 0.4743) + 영점 s = -2.6
%  - K = 1 에서 GM = 8.77 dB, PM = 44.67 도, %OS = 20.77 %
%  - PM 에서 오버슈트를 짐작한다 : zeta = PM*0.01 -> %OS 공식.
%    여기서는 예측 20.83 % 대 실측 20.77 % 로 거의 맞는다
%  - 거꾸로도 쓴다 : 목표 %OS 에서 zeta 를 역산하고 PM 목표로 바꾼다
%    (%OS 10 % 라면 PM 약 59 도가 필요하다)
%  - K 를 0.7 -> 1 -> 1.2 로 키우면
%      크기 선도만 위로 평행이동하고 위상 선도는 그대로다
%      wcg (위상교차) 는 전혀 안 움직인다 -> GM 이 평행이동한 dB 만큼 줄어든다
%      wcp (이득교차) 는 커진다 -> tr 은 1.86 -> 1.39 -> 1.23 s 로 짧아진다
%      대신 PM 은 69.6 -> 44.7 -> 31.9 도, %OS 는 5.0 -> 20.8 -> 29.1 % 로 나빠진다
%      정착시간은 9.0 -> 13.2 -> 17.1 s 로 오히려 길어진다
%  - 그래서 K 하나로는 빠르기와 안정성을 동시에 얻지 못한다.
%    위상을 보태 주는 보상기가 필요하다 -> 11주차 진상/지상 보상
