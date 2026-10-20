%% W11A_01 — 루프이득 L 과 두 식 S, T
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 1절 ~ 2절에 대응합니다.
% 절 안에서 Ctrl+Enter 를 누르면 그 절만 실행됩니다.
%
% 바꿔 볼 것
%   - 1절의 Kp 를 10, 100, 1000 으로
%   - 2절의 w_list 에 다른 주파수를 추가
%   - 3절의 Cm 에서 500 을 바꿔 보기 (교차주파수가 따라 움직인다)

clear; clc; close all;
s = tf('s');

%% 1. 가장 작은 예 — 루프이득이 숫자 하나로 정해지는 경우
% L = Kp/s 는 적분기 하나뿐인 루프입니다.
% 이 경우 교차주파수가 곧 Kp 입니다. 바꿔 가며 확인해 봅니다.

Kp = 100;                      % <-- 10, 100, 1000 으로 바꿔 보기

L = Kp/s;
T = feedback(L, 1);            % 지령 -> 출력
S = 1 - T;                     % 오차가 남는 비율

w_list = [0.1 1 10 100 1000]';
L_dB = 20*log10(squeeze(abs(freqresp(L, w_list))));
S_dB = 20*log10(squeeze(abs(freqresp(S, w_list))));
T_dB = 20*log10(squeeze(abs(freqresp(T, w_list))));

table(w_list, L_dB, S_dB, T_dB, ...
    'VariableNames', {'w_rad_s', 'L_dB', 'S_dB', 'T_dB'})

% 교차주파수를 재 봅니다. Kp 와 같은 값이 나와야 합니다.
[~, PM, ~, wc] = margin(L);
fprintf('Kp = %g,  wc = %g rad/s,  PM = %.1f deg\n', Kp, wc, PM);

%% 2. S + T = 1 을 수치로 확인한다
% 어떤 주파수에서도 정확히 1 이 나옵니다. 설계로 깰 수 없는 제약입니다.

w_chk = [0.01 0.1 1 10 100 1000 1e4]';
Sv = squeeze(freqresp(S, w_chk));
Tv = squeeze(freqresp(T, w_chk));

table(w_chk, abs(Sv), abs(Tv), abs(Sv + Tv), ...
    'VariableNames', {'w_rad_s', 'S_크기', 'T_크기', 'S_plus_T_크기'})

% 그림으로도 봅니다.
w = logspace(-2, 4, 400);
Sm_ = squeeze(abs(freqresp(S, w)));
Tm_ = squeeze(abs(freqresp(T, w)));

tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
semilogx(w, 20*log10(Sm_), 'LineWidth', 2, 'DisplayName', '|S|');
semilogx(w, 20*log10(Tm_), 'LineWidth', 2, 'DisplayName', '|T|');
set(gca, 'XScale', 'log');
yline(0, 'k--'); yline(-3, 'k:');
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]');
legend('Location', 'west');
title('한쪽이 작으면 다른 쪽은 1 이다');

nexttile; hold on; grid on;
semilogx(w, 20*log10(abs(squeeze(freqresp(S, w)) + squeeze(freqresp(T, w)))), ...
    'LineWidth', 2.5, 'Color', [0.85 0.33 0.10]);
set(gca, 'XScale', 'log');
ylim([-1 1]);
xlabel('주파수 [rad/s]'); ylabel('|S+T| [dB]');
title('|S+T| 은 모든 주파수에서 0 dB');

%% 3. 모터 예제 — 영점이 극점을 지운다
% 담당교수 강의자료의 예제입니다.
%   P = 0.1/(0.5s+2),  C = (500s+2000)/s
% 손으로 곱하면 (s+4) 가 약분되어 L = 100/s 가 됩니다.

P = 0.1/(0.5*s + 2);
C = (500*s + 2000)/s;

Lm = P*C;
Lm_min = minreal(Lm);          % 약분 결과를 확인

fprintf('\n플랜트 극점 : %g\n', pole(P));
fprintf('제어기 영점 : %g\n', zero(C));
Lm_min                          % 100/s 가 나온다

Sm = 1/(1 + Lm_min);
Tm = Lm_min/(1 + Lm_min);

% 네 숫자를 읽습니다.
[GM, PM2, ~, wc2] = margin(Lm_min);
table(20*log10(GM), PM2, wc2, bandwidth(Tm), ...
    'VariableNames', {'GM_dB', 'PM_deg', 'wc_rad_s', 'wb_rad_s'})

% L, S, T 를 한 그림에
w2 = logspace(-1, 4, 400);
tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
semilogx(w2, 20*log10(squeeze(abs(freqresp(Lm_min, w2)))), 'LineWidth', 2.5, ...
    'DisplayName', '|L|');
semilogx(w2, 20*log10(squeeze(abs(freqresp(Sm, w2)))), 'LineWidth', 2, ...
    'DisplayName', '|S|');
semilogx(w2, 20*log10(squeeze(abs(freqresp(Tm, w2)))), 'LineWidth', 2, ...
    'DisplayName', '|T|');
set(gca, 'XScale', 'log');
yline(0, 'k--'); xline(wc2, 'k:');
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]');
legend('Location', 'southwest');
title(sprintf('모터 루프 — wc = %g rad/s 에서 세 곡선이 모인다', wc2));

nexttile; hold on; grid on;
t = linspace(0, 0.08, 400)';
plot(t, step(Tm, t), 'LineWidth', 2.5, 'DisplayName', 'T : 계단 추종');
plot(t, step(Sm, t), 'LineWidth', 2, 'DisplayName', 'S : 남는 오차');
yline(1, 'k:'); yline(0, 'k:');
xlabel('시간 [s]'); ylabel('출력');
legend('Location', 'east');
title('오버슈트가 없다 — PM 90 도의 결과');

%% 4. 저주파·고주파 근사가 맞는지 확인한다
% |L| 이 크면 |S| = 1/|L|,  |L| 이 작으면 |T| = |L|

w3 = logspace(-1, 4, 200);
Lm3 = squeeze(abs(freqresp(Lm_min, w3)));
Sm3 = squeeze(abs(freqresp(Sm, w3)));
Tm3 = squeeze(abs(freqresp(Tm, w3)));

hold on; grid on;
semilogx(w3, 20*log10(Sm3), 'LineWidth', 2.5, 'DisplayName', '|S| 실제');
semilogx(w3, -20*log10(Lm3), '--', 'LineWidth', 2, 'DisplayName', '1/|L| 근사');
semilogx(w3, 20*log10(Tm3), 'LineWidth', 2.5, 'DisplayName', '|T| 실제');
semilogx(w3, 20*log10(Lm3), ':', 'LineWidth', 2, 'DisplayName', '|L| 근사');
set(gca, 'XScale', 'log');
yline(0, 'k--'); xline(wc2, 'k:');
ylim([-60 60]);
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]');
legend('Location', 'southwest');
title('교차주파수에서 멀어질수록 근사가 잘 맞는다');

%% 5. 숙제용 연습 — 플랜트를 바꿔 보기
% 극점이 둘인 플랜트로 바꾸면 무엇이 달라지는지 봅니다.
% 약분이 일어나지 않으므로 L 이 100/s 가 아닙니다.

P2 = 100/(s*(s + 10));         % 적분기 + 극점 하나
C2 = 1;                        % 비례 제어기, 이득 1

L2 = P2*C2;
T2 = feedback(L2, 1);
[GM2, PMx, ~, wcx] = margin(L2);

table(20*log10(GM2), PMx, wcx, bandwidth(T2), stepinfo(T2).Overshoot, ...
    'VariableNames', {'GM_dB', 'PM_deg', 'wc', 'wb', 'OS_퍼센트'})

% 질문
%   - PM 이 90 도보다 작아졌습니다. 왜 그런가요 (힌트 : wc 에서의 기울기)
%   - C2 를 2 로 올리면 PM 이 어떻게 변하나요
%   - wb / wc 비율이 1.5 근처인지 확인해 보세요
