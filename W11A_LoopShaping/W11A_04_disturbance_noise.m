%% W11A_04 — 외란과 센서 잡음 : 되먹임이 벌는 것과 잃는 것
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 5절 ~ 6-1절에 대응합니다.
%
% 바꿔 볼 것
%   - 1절의 w_dist 를 0.1, 2*pi, 50, 200 으로 (고주파에서는 안 줄어든다)
%   - 3절의 noise_std 를 키워 보기
%   - 4절의 K 를 올려 외란은 좋아지고 잡음은 나빠지는 것 확인

clear; clc; close all;
s = tf('s');

% 학기 플랜트 — 담당교수 강의자료의 모터 예제
P = 0.1/(0.5*s + 2);
C = (500*s + 2000)/s;

L = minreal(P*C);               % = 100/s
S = 1/(1 + L);                  % = s/(s+100)
T = L/(1 + L);                  % = 100/(s+100)

%% 1. 출력외란 — 전달함수가 바로 S 다
% 개루프에서는 y/d_o = 1 (그대로 나온다)
% 폐루프에서는 y/d_o = S   (|L| 만큼 줄어든다)

w_dist = 2*pi;                  % <-- 0.1, 2*pi, 50, 200 으로 바꿔 보기

S_mag = abs(freqresp(S, w_dist));
L_mag = abs(freqresp(L, w_dist));

fprintf('외란 주파수 %g rad/s 에서\n', w_dist);
fprintf('  |L|  = %.3f  (%.2f dB)\n', L_mag, 20*log10(L_mag));
fprintf('  개루프 y/d = 1.000  ( 0.00 dB)\n');
fprintf('  폐루프 y/d = %.5f  (%.2f dB)\n', S_mag, 20*log10(S_mag));
fprintf('  되먹임이 번 양 = %.2f dB   ( = |1+L| )\n', -20*log10(S_mag));

% 손계산과 대조 : |S(jw)| = w/sqrt(w^2 + 100^2)
hand = w_dist/sqrt(w_dist^2 + 100^2);
fprintf('\n손계산 : %g / sqrt(%g^2 + 100^2) = %.6f -> %.4f dB\n', ...
    w_dist, w_dist, hand, 20*log10(hand));
fprintf('freqresp : %.6f -> %.4f dB\n', S_mag, 20*log10(S_mag));

% 시간영역으로도 확인
t = (0:1e-4:6)';
y_cl = lsim(S, sin(w_dist*t), t);
amp = max(y_cl(t > 4));          % 정상상태 진폭
fprintf('lsim 정상상태 진폭 : %.6f -> %.4f dB\n', amp, 20*log10(amp));

tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
plot(t, sin(w_dist*t), 'LineWidth', 1.2, 'Color', [0.6 0.6 0.6], ...
    'DisplayName', '개루프 (외란 그대로)');
plot(t, y_cl, 'LineWidth', 2.2, 'DisplayName', '폐루프');
xlim([3 6]);
xlabel('시간 [s]'); ylabel('출력 y');
legend('Location', 'northeast');
title(sprintf('%g rad/s 정현 외란 — %.1f dB 줄었다', w_dist, -20*log10(amp)));

nexttile; hold on; grid on;
w = logspace(-1, 4, 400);
semilogx(w, zeros(size(w)), 'LineWidth', 2, 'Color', [0.6 0.6 0.6], ...
    'DisplayName', '개루프 (항상 0 dB)');
semilogx(w, 20*log10(squeeze(abs(freqresp(S, w)))), 'LineWidth', 2.5, ...
    'DisplayName', '폐루프 |S|');
set(gca, 'XScale', 'log');
yline(0, 'k--'); xline(w_dist, 'k:');
xlabel('주파수 [rad/s]'); ylabel('y/d_o [dB]');
legend('Location', 'southeast');
title('고주파 외란은 억제할 수 없다');

%% 1-1. 외란을 더 줄이려면 — PI 의 꺾이는 자리를 옮긴다
% 1절에서 1 Hz 외란이 -24.05 dB 로 줄었습니다. 더 줄이고 싶다면
% 그 주파수에서 |L| 을 더 올려야 합니다. 어떻게 올리는가가 설계입니다.
%
% PI 제어기를 담당교수 강의자료의 표기로 다시 씁니다.
%
%   C(s) = K*(Ti*s + 1)/(Ti*s),      Ki = K/Ti
%
% - K 는 고주파쪽 평평한 이득입니다 (교차주파수를 정합니다)
% - 1/Ti 가 **꺾이는 자리**입니다. 이 왼쪽에서 기울기가 -20 dB/dec 로 올라갑니다
% - 그래서 **1/Ti 를 오른쪽으로 옮기면** 저주파 이득이 통째로 올라갑니다
%
% 지금 쓰는 C = (500s + 2000)/s 는 K = 500, 1/Ti = 4 와 똑같습니다.
% 확인 : 500*(s/4 + 1)/(s/4) = 500*(s + 4)/s = (500s + 2000)/s

K_pi = 500;
invTi_list = [4 10 20 40]';
q = numel(invTi_list);
pm1 = zeros(q,1); wc1 = zeros(q,1); wb1 = zeros(q,1);
SdB1 = zeros(q,1); os1 = zeros(q,1); Ki1 = zeros(q,1);

for k = 1:q
    Ti = 1/invTi_list(k);
    Ck = K_pi*(Ti*s + 1)/(Ti*s);
    Ki1(k) = K_pi/Ti;

    Lk = minreal(P*Ck);
    Sk = 1/(1 + Lk);
    Tk = Lk/(1 + Lk);

    [~, pm1(k), ~, wc1(k)] = margin(Lk);
    wb1(k) = bandwidth(Tk);
    SdB1(k) = 20*log10(abs(freqresp(Sk, w_dist)));
    os1(k) = stepinfo(Tk).Overshoot;
end

table(invTi_list, Ki1, pm1, wc1, wb1, SdB1, os1, ...
    'VariableNames', {'꺾이는자리_rad_s', 'Ki', 'PM_deg', 'wc_rad_s', ...
                      'wb_rad_s', '외란_1Hz_dB', 'OS_퍼센트'})

% 읽는 법
%   - 꺾이는 자리를 4 에서 20 으로 옮기면 1 Hz 외란이 -24.05 에서 -32.90 dB 로
%     8.85 dB 더 줄어든다. 즉 외란이 추가로 2.8 배 작아진다
%   - 그 대가는 PM 이 90 도에서 81 도로 9 도 줄고, 오버슈트가 0 에서 8.8 % 로 생기는 것
%   - 교차주파수는 100 에서 102 로 거의 그대로다.
%     저주파만 들어올렸기 때문이다. **이것이 loop shaping 이다**
%   - 40 까지 더 가면 -38.67 dB 까지 되지만 오버슈트가 15.6 % 가 된다

w1 = logspace(-1, 4, 500);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
for k = 1:q
    Ti = 1/invTi_list(k);
    Lk = minreal(P*K_pi*(Ti*s + 1)/(Ti*s));
    semilogx(w1, 20*log10(squeeze(abs(freqresp(Lk, w1)))), 'LineWidth', 2, ...
        'DisplayName', sprintf('1/Ti = %g', invTi_list(k)));
end
set(gca, 'XScale', 'log');
yline(0, 'k--'); xline(w_dist, 'k:');
xlabel('주파수 [rad/s]'); ylabel('|L| [dB]');
legend('Location', 'southwest');
title('저주파만 올라가고 교차주파수는 그대로다');

nexttile; hold on; grid on;
for k = 1:q
    Ti = 1/invTi_list(k);
    Lk = minreal(P*K_pi*(Ti*s + 1)/(Ti*s));
    Sk = 1/(1 + Lk);
    semilogx(w1, 20*log10(squeeze(abs(freqresp(Sk, w1)))), 'LineWidth', 2, ...
        'DisplayName', sprintf('1/Ti = %g', invTi_list(k)));
end
set(gca, 'XScale', 'log');
yline(0, 'k--'); xline(w_dist, 'k:', '1 Hz');
xlabel('주파수 [rad/s]'); ylabel('|S| = y/d_o [dB]');
legend('Location', 'southeast');
title('1 Hz 에서 더 깊이 내려간다');

%% 2. 입력외란 — 개루프는 제어기로 어쩔 수가 없다
% 개루프 y/d_i = P        <- C 가 아예 나타나지 않는다
% 폐루프 y/d_i = P*S

PS = minreal(P*S);

w_list = [0.1 1 2 2*pi 20 100 500]';
open_dB   = 20*log10(squeeze(abs(freqresp(P,  w_list))));
closed_dB = 20*log10(squeeze(abs(freqresp(PS, w_list))));
gain_dB   = open_dB - closed_dB;
L_dB      = 20*log10(squeeze(abs(freqresp(L, w_list))));

table(w_list, L_dB, open_dB, closed_dB, gain_dB, ...
    'VariableNames', {'w_rad_s', 'L_dB', '개루프_dB', '폐루프_dB', '되먹임이_번_dB'})

% 저주파에서 번 양이 |L| 과 같은 것을 확인하세요.
% 교차주파수(100) 에서는 3 dB 밖에 안 됩니다.

% 계단 입력외란 — 가장 선명한 비교
t2 = (0:1e-4:0.2)';
y_open   = lsim(P,  ones(size(t2)), t2);     % 되먹임 없음
y_closed = lsim(PS, ones(size(t2)), t2);     % 되먹임 있음

hold on; grid on;
plot(t2, y_open, 'LineWidth', 2.2, 'Color', [0.6 0.6 0.6], ...
    'DisplayName', '개루프 : 영구히 틀어진 채로 남는다');
plot(t2, y_closed, 'LineWidth', 2.5, 'Color', [0.85 0.33 0.10], ...
    'DisplayName', '폐루프 : 0 으로 되돌아온다');
yline(dcgain(P), 'k:', '개루프 정상상태 = P(0)');
yline(0, 'k--');
xlabel('시간 [s]'); ylabel('출력 y');
legend('Location', 'east');
title('계단 입력외란 — 적분기가 있어 정상상태 오차가 0 이 된다');

%% 3. 센서 잡음 — 전달함수가 -T 다
% 지령 추종과 똑같은 T 이므로 피할 방법이 없습니다.
% 다행히 센서 잡음은 대개 고주파입니다.

noise_std = 0.02;               % <-- 0.05, 0.1 로 키워 보기
noise_ts  = 1e-4;               % 잡음 샘플 간격
rng(0);                         % 재현 가능하게

t3 = (0:noise_ts:0.5)';
n_sig = noise_std*randn(size(t3));

y_ref   = lsim(T,  ones(size(t3)), t3);      % 계단 지령에 대한 응답
y_noise = lsim(-T, n_sig, t3);               % 잡음이 만든 출력
y_total = y_ref + y_noise;

% 나온 값이 맞는지 식으로 확인한다
%
%   샘플 간격 noise_ts 로 만든 백색잡음은 0 부터 pi/noise_ts 까지
%   **고르게 퍼져** 있습니다. 여기서는 0 ~ 31416 rad/s 입니다.
%   그런데 -T 는 대역폭 100 rad/s 까지만 통과시킵니다.
%   그래서 띠의 아주 일부만 출력에 나옵니다.
%
%   출력 분산 = (입력 분산 x noise_ts / (2*pi)) x 적분 |T(jw)|^2 dw
%               (적분 구간은 -pi/noise_ts ~ +pi/noise_ts)
%
%   적분은 손으로 하지 않고 trapz 로 수치적으로 합니다.

w_band = linspace(-pi/noise_ts, pi/noise_ts, 400001);
T2 = squeeze(abs(freqresp(T, abs(w_band)))).^2;
var_pred = noise_std^2*noise_ts/(2*pi)*trapz(w_band, T2);

% [주의] 표준편차를 재려면 기록이 충분히 길어야 합니다.
%        위의 0.5 초짜리 t3 는 그림을 보기에는 좋지만, 대역폭 100 rad/s 기준
%        독립된 표본이 열 개 남짓이라 표준편차가 30 % 넘게 틀어집니다.
%        그래서 숫자 확인은 20 초짜리 긴 기록으로 따로 합니다.
t3_long = (0:noise_ts:20)';
rng(0);
n_long = noise_std*randn(size(t3_long));
y_long = lsim(-T, n_long, t3_long);
std_meas = std(y_long(t3_long > 0.2));

fprintf('\n잡음 입력 표준편차 : %.4f   (띠 폭 0 ~ %.0f rad/s)\n', ...
    std(n_long), pi/noise_ts);
fprintf('출력 표준편차 : 식 %.6f  대  실측 %.6f  (차이 %.1f %%)\n', ...
    sqrt(var_pred), std_meas, 100*abs(std_meas - sqrt(var_pred))/sqrt(var_pred));
fprintf('  -> 입력의 %.1f %% 만 남았다 (대역폭 %.0f rad/s 밖은 막혔다)\n', ...
    100*std_meas/std(n_long), bandwidth(T));
fprintf('  -> 다만 **대역폭 안의** 잡음은 |T| = 1 이므로 그대로 통과한다.\n');
fprintf('     막을 방법이 없고, 대역폭을 줄이는 것 말고는 손쓸 데가 없다.\n');

tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
w3 = logspace(-1, 5, 400);
semilogx(w3, 20*log10(squeeze(abs(freqresp(T, w3)))), 'LineWidth', 2.5);
set(gca, 'XScale', 'log');
yline(0, 'k--'); yline(-3, 'k:');
xline(bandwidth(T), 'k:');
xlabel('주파수 [rad/s]'); ylabel('|n -> y| = |T| [dB]');
title('대역폭 밖의 잡음만 막힌다');

nexttile; hold on; grid on;
plot(t3, y_total, 'LineWidth', 1.0, 'DisplayName', '잡음 포함 출력');
plot(t3, y_ref, 'LineWidth', 2.5, 'DisplayName', '잡음 없을 때');
yline(1, 'k:');
xlabel('시간 [s]'); ylabel('출력 y');
legend('Location', 'southeast');
title('측정한 값에 잡음이 섞여 들어온다');

%% 4. 맞바꿈 — 대역폭을 키우면 외란은 좋아지고 잡음은 나빠진다
% 제어기 이득을 올려 가며 두 가지를 동시에 재 봅니다.

K_list = [0.2 0.5 1 2 5]';
m = numel(K_list);
d_att = zeros(m,1); n_amp = zeros(m,1); wbv = zeros(m,1);

t4 = (0:1e-4:1)';
rng(0);
n4 = 0.02*randn(size(t4));
d4 = sin(2*pi*t4);               % 1 Hz 출력외란

for k = 1:m
    Lk = K_list(k)*L;
    Sk = 1/(1 + Lk);
    Tk = Lk/(1 + Lk);
    wbv(k) = bandwidth(Tk);
    yd = lsim(Sk, d4, t4);
    yn = lsim(-Tk, n4, t4);
    d_att(k) = 20*log10(max(abs(yd(t4 > 0.6))));   % 외란 남은 양 [dB]
    n_amp(k) = std(yn(t4 > 0.3));                  % 잡음 기여 표준편차
end

table(K_list, wbv, d_att, n_amp, ...
    'VariableNames', {'K배수', 'wb_rad_s', '외란_남은양_dB', '잡음_표준편차'})

hold on; grid on;
yyaxis left
plot(wbv, d_att, '-o', 'LineWidth', 2.2);
ylabel('외란 남은 양 [dB]  (낮을수록 좋다)');
yyaxis right
plot(wbv, n_amp, '-s', 'LineWidth', 2.2);
ylabel('잡음 기여 (낮을수록 좋다)');
set(gca, 'XScale', 'log');
xlabel('대역폭 wb [rad/s]');
title('대역폭을 키우면 한쪽은 좋아지고 한쪽은 나빠진다');

%% 5. 오차 예산 — 네 항을 한 번에
%   y = T*r + S*d_o + P*S*d_i - T*n

t5 = (0:1e-4:1)';
rng(0);
r5  = ones(size(t5));            % 계단 지령
do5 = 0.3*sin(2*pi*t5);          % 출력외란 1 Hz
di5 = 2*ones(size(t5));          % 입력외란 계단
n5  = 0.02*randn(size(t5));      % 센서 잡음

y_r  = lsim(T,  r5,  t5);
y_do = lsim(S,  do5, t5);
y_di = lsim(PS, di5, t5);
y_n  = lsim(-T, n5,  t5);
y_all = y_r + y_do + y_di + y_n;

idx = t5 > 0.5;                  % 정상상태 구간
table([max(abs(r5)); max(abs(do5)); max(abs(di5)); std(n5)], ...
      [max(abs(y_r(idx))); max(abs(y_do(idx))); ...
       max(abs(y_di(idx))); std(y_n(idx))], ...
    'RowNames', {'지령_r', '출력외란_do', '입력외란_di', '잡음_n'}, ...
    'VariableNames', {'입력_크기', '출력_기여'})

hold on; grid on;
plot(t5, y_all, 'LineWidth', 1.2, 'DisplayName', '전부 합한 실제 출력');
plot(t5, y_r, 'LineWidth', 2.5, 'DisplayName', '지령만 있을 때 (T*r)');
yline(1, 'k:');
xlabel('시간 [s]'); ylabel('출력 y');
legend('Location', 'southeast');
title('지령 + 외란 둘 + 잡음이 동시에 들어온 결과');

% 질문
%   - 입력외란의 기여가 정상상태에서 0 인 이유는 무엇인가요 (힌트 : 적분기)
%   - 잡음 기여를 반으로 줄이는 두 가지 방법은 무엇인가요
%   - 1 Hz 외란을 40 dB 줄이려면 그 주파수에서 |L| 이 몇 dB 여야 하나요
