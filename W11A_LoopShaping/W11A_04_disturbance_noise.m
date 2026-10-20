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
rng(0);                         % 재현 가능하게

t3 = (0:1e-4:0.5)';
n_sig = noise_std*randn(size(t3));

y_ref   = lsim(T,  ones(size(t3)), t3);      % 계단 지령에 대한 응답
y_noise = lsim(-T, n_sig, t3);               % 잡음이 만든 출력
y_total = y_ref + y_noise;

fprintf('\n잡음 입력 표준편차 : %.4f\n', std(n_sig));
fprintf('출력에 나온 표준편차 : %.4f\n', std(y_noise(t3 > 0.2)));
fprintf('  -> 저주파 성분은 |T| = 1 로 100 %% 통과한다\n');

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
