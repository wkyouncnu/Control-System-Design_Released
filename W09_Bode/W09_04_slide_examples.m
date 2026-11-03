%% W09_04_slide_examples.m
%  9주차 실습 (4) : 교수자 강의자료 06_FrequencyResponse 1~16쪽의 예제
%
%  이 스크립트에서 답할 질문
%    Q1. 입력 진폭 A 는 출력에서 어떻게 되는가?            -> 1절
%    Q2. RC 회로에 1 Hz 와 3 Hz 를 넣으면 어떻게 되는가?   -> 2절
%    Q3. 가로축을 로그로, 세로축을 dB 로 바꾸면 뭐가 좋은가 -> 3절
%    Q4. 이득 K 를 바꾸면 보드 선도가 어떻게 움직이는가?    -> 4절
%
%  대응하는 강의노트 : W09_LectureNote.mlx 의 0-1-1 / 2-3 / 3-2 / 5-5 절
%
%  이 스크립트는 공통 함수(dg_*, plant_*)를 쓰지 않습니다.
%  MATLAB 기본 명령만으로 적어서, 절마다 따로 떼어 실행할 수 있습니다.
%
%  제어시스템설계 9주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 1. 입력 진폭 A 는 출력에서 A 곱하기 크기가 된다  (강의자료 2쪽)
%  선형 시스템이므로 입력을 A 배 하면 출력도 정확히 A 배가 된다.
%  그래서 보드 선도에는 A 가 등장하지 않는다 (비를 재기 때문에 약분된다).

G_a  = tf(1, [1 1]);                % G(s) = 1/(s+1)
w_a  = 1;                           % 넣을 주파수 [rad/s]
A_in = 2;                           % 입력 진폭. 일부러 1 이 아닌 값으로

Gj_a      = freqresp(G_a, w_a);     % 복소수 G(jw)
amp_pred  = A_in * abs(Gj_a)        % 예상 출력 진폭 = A * |G|
phase_deg = rad2deg(angle(Gj_a))    % 예상 위상 [도]

t_a = (0:0.001:30)';                % 정상상태까지 충분히 길게
u_a = A_in * sin(w_a*t_a);
y_a = lsim(G_a, u_a, t_a);

amp_meas = max(y_a(end-6000:end))   % 뒤쪽 한 주기에서 실제로 잰 진폭

% A 를 바꿔 가며 비가 일정한지 확인한다 — 이것이 "A 가 약분된다" 는 뜻
A_list   = [0.5; 1; 2; 5]';
amp_list = zeros(1,4);
for i = 1:4
    y_i = lsim(G_a, A_list(i)*sin(w_a*t_a), t_a);
    amp_list(i) = max(y_i(end-6000:end));
end
A_in_col   = A_list';
amp_out    = amp_list';
ratio_col  = amp_out ./ A_in_col;   % 네 값이 모두 |G(j1)| = 0.7071 이어야 한다
table(A_in_col, amp_out, ratio_col)

figure('Name','1절: 진폭 A');
plot(t_a, u_a, 'LineWidth', 1.6); hold on;
plot(t_a, y_a, 'LineWidth', 1.6); grid on;
xlim([25 30]);                      % 정상상태 구간만 확대
xlabel('시간 [s]'); ylabel('신호');
legend('입력 A sin(\omega t)', '출력', 'Location', 'southeast');
title(sprintf('A = %g 일 때 출력 진폭 %.4f (= A x 0.7071)', A_in, amp_meas));

%% 2. RC 회로에 1 Hz 와 3 Hz 를 넣는다  (강의자료 3쪽)
%  R = 100 옴, C = 0.001 F -> 시정수 RC = 0.1 s -> G(s) = 1/(0.1s+1)
%  Simulink Sine Wave 블록의 Frequency 칸은 rad/s 이므로 2*pi*f 를 넣는다.

R_rc   = 100;                       % 저항 [옴]
C_rc   = 0.001;                     % 축전기 [F]
tau_rc = R_rc * C_rc                % 시정수 [s]
G_rc   = tf(1, [tau_rc 1]);

f_rc = [1; 3];                      % 넣을 주파수 [Hz]
w_rc = 2*pi*f_rc                    % [rad/s] — 1 Hz 는 6.283 rad/s

% 손으로 유도한 식과 MATLAB 결과를 나란히 놓는다
mag_hand = 1 ./ sqrt(1 + (tau_rc*w_rc).^2);
ph_hand  = -atand(tau_rc*w_rc);
Gj_rc    = squeeze(freqresp(G_rc, w_rc));
mag_mat  = abs(Gj_rc);
ph_mat   = rad2deg(angle(Gj_rc));
table(f_rc, w_rc, mag_hand, mag_mat, ph_hand, ph_mat)

% 시간응답으로도 같은 값이 나오는지 — Simulink Scope 가 보여 주는 것
figure('Name','2절: RC 회로');
for i = 1:2
    subplot(2,1,i);
    t_i = (0:0.001:2)';
    u_i = sin(w_rc(i)*t_i);
    y_i = lsim(G_rc, u_i, t_i);
    plot(t_i, u_i, 'LineWidth', 1.4); hold on;
    plot(t_i, y_i, 'LineWidth', 1.8); grid on;
    yline( mag_mat(i), 'k:');
    yline(-mag_mat(i), 'k:');
    ylim([-1.25 1.25]);
    xlabel('시간 [s]'); ylabel('신호');
    legend('입력', '출력', 'Location', 'southeast');
    title(sprintf('f = %g Hz : 크기 %.3f, 위상 %.0f 도', ...
          f_rc(i), mag_mat(i), ph_mat(i)));
end

%% 3. 가로축을 로그로, 세로축을 dB 로  (강의자료 12쪽)
%  보드 선도의 정의 : 가로축 로그 눈금 + 세로축 20*log10|G|
%  극점이 100 배 떨어져 있는 시스템으로 두 방식을 비교한다.

G_v = tf(1, conv([1 1], [0.01 1]));   % 극점 -1 과 -100

figure('Name','3절: 선형축 대 로그축');

subplot(1,2,1);                        % 선형 가로축 + 배율 세로축
w_lin = linspace(0.01, 200, 4000);
plot(w_lin, squeeze(abs(freqresp(G_v, w_lin))), 'LineWidth', 1.8); grid on;
xlabel('\omega [rad/s] (선형)'); ylabel('|G| (배율)');
title('선형축 : 정보가 왼쪽 끝에 뭉친다');

subplot(1,2,2);                        % 로그 가로축 + dB 세로축
w_log = logspace(-2, 4, 1200);
semilogx(w_log, 20*log10(squeeze(abs(freqresp(G_v, w_log)))), 'LineWidth', 1.8);
grid on; hold on;
xline(1,   'k:');                      % 첫 번째 꺾임점
xline(100, 'k:');                      % 두 번째 꺾임점
xlabel('\omega [rad/s] (로그)'); ylabel('|G|_{dB} = 20log_{10}|G|');
title('로그축 + dB : 기울기 0 \rightarrow -20 \rightarrow -40');

% 배율과 dB 를 서로 바꿔 본다 — 외워 둘 네 값
ratio_tbl = [0.001; 0.01; 1/sqrt(2); 1; sqrt(2); 2; 10; 1000];
dB_tbl    = 20*log10(ratio_tbl);
back_tbl  = 10.^(dB_tbl/20);          % 되돌아오는지 확인
table(ratio_tbl, dB_tbl, back_tbl)

%% 4. 이득 K 를 바꾸면 크기만 평행이동, 위상은 그대로
%  20log10|K G| = 20log10 K + 20log10|G|   -> 크기는 통째로 위아래
%  angle(K G)   = angle(G)        (K > 0)  -> 위상은 전혀 안 움직인다
%  그래서 K 를 키우면 교차주파수와 대역폭이 커지고 응답이 빨라진다.

G_k = tf(1, [1 1 0]);               % G(s) = 1/(s(s+1))
K_k = [0.5; 2; 8];
w_k = 1;                            % 평행이동 확인용 주파수 하나

shift_dB = 20*log10(K_k)            % 더해질 상수 [dB] : -6.02, +6.02, +18.06
base_dB  = 20*log10(abs(freqresp(G_k, w_k)));
pred_dB  = base_dB + shift_dB;      % 예상값

meas_dB = zeros(3,1);  meas_ph = zeros(3,1);
wc_col  = zeros(3,1);  pm_col  = zeros(3,1);
bw_col  = zeros(3,1);  tr_col  = zeros(3,1);
for i = 1:3
    Gi = K_k(i) * G_k;
    meas_dB(i) = 20*log10(abs(freqresp(Gi, w_k)));
    meas_ph(i) = rad2deg(angle(freqresp(Gi, w_k)));
    [~, pm_col(i), ~, wc_col(i)] = margin(Gi);
    Ti         = feedback(Gi, 1);
    bw_col(i)  = bandwidth(Ti);
    tr_col(i)  = stepinfo(Ti).RiseTime;
end
table(K_k, shift_dB, pred_dB, meas_dB, meas_ph)

% 위상이 정말 안 움직이는지 — 0 이 나와야 한다
phase_spread = max(meas_ph) - min(meas_ph)

% K 를 키우면 빨라진다 — 교차주파수 / 대역폭 / 상승시간을 한 표로
table(K_k, wc_col, bw_col, tr_col, pm_col)

figure('Name','4절: 이득을 바꾸면');

subplot(1,3,1);                     % 크기 : 평행이동
w_b = logspace(-1.5, 2, 1000);
hold on; grid on; set(gca, 'XScale', 'log');
for i = 1:3
    semilogx(w_b, shift_dB(i) + 20*log10(squeeze(abs(freqresp(G_k, w_b)))), ...
             'LineWidth', 1.8);
end
yline(0, 'k--');
xlabel('\omega [rad/s]'); ylabel('|KG| [dB]');
legend('K = 0.5', 'K = 2', 'K = 8', 'Location', 'southwest');
title('크기 : 모양 그대로, 위아래로만');

subplot(1,3,2);                     % 위상 : 세 개가 겹친다
ph_b = rad2deg(unwrap(angle(squeeze(freqresp(G_k, w_b)))));
hold on; grid on; set(gca, 'XScale', 'log');
lw_b = [6 3.5 1.6];                 % 겹친 것을 보이려고 굵기를 달리한다
for i = 1:3
    semilogx(w_b, ph_b, 'LineWidth', lw_b(i));
end
yline(-180, 'r:');
xlabel('\omega [rad/s]'); ylabel('\angle KG [도]');
legend('K = 0.5', 'K = 2', 'K = 8', 'Location', 'southwest');
title('위상 : 완전히 겹친다');

subplot(1,3,3);                     % 그래서 빨라진다
t_b = (0:0.01:25)';
hold on; grid on;
for i = 1:3
    plot(t_b, step(feedback(K_k(i)*G_k, 1), t_b), 'LineWidth', 1.8);
end
yline(1, 'k--');
xlabel('시간 [s]'); ylabel('출력');
legend(sprintf('K = 0.5 : t_r %.2f s', tr_col(1)), ...
       sprintf('K = 2 : t_r %.2f s',   tr_col(2)), ...
       sprintf('K = 8 : t_r %.2f s',   tr_col(3)), ...
       'Location', 'southeast');
title('\omega_c 가 커지면 빨라진다');

% 눈대중 식 t_r = 1.8 / wBW 과 비교
tr_rule = 1.8 ./ bw_col;
table(K_k, bw_col, tr_col, tr_rule)

%% 5. 이번 실습의 정리
%  - 입력 진폭 A 는 출력에서 A*|G| 가 된다. 비를 재므로 보드 선도에는 A 가 없다
%  - Hz 와 rad/s 는 2*pi 배 차이다. Simulink Sine Wave 의 Frequency 는 rad/s
%  - 보드 선도 = 가로축 로그 + 세로축 20*log10|G| (위상은 도 단위 그대로)
%  - K 를 키우면 크기는 20log10(K) 만큼 평행이동, 위상은 그대로
%  - 그래서 K 를 키우면 wc 와 wBW 가 커져 응답이 빨라지고, 대신 PM 이 줄어
%    오버슈트가 커진다 (10주차에서 숫자로 재고, 11주차에서 위상을 보탠다)
