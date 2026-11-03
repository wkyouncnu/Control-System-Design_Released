%% W09_05_rc_simulink.m
%  9주차 실습 (5) : 교수자 강의자료 3쪽의 Simulink 예제를 직접 돌려 본다
%
%  이 스크립트에서 답할 질문
%    Q1. 모델을 돌리면 강의자료의 네 숫자가 정말 나오는가?     -> 1절
%    Q2. 크기비와 위상차를 파형에서 어떻게 재는가?             -> 2절
%    Q3. 손계산 · Simulink · bode 세 값이 일치하는가?          -> 3절
%
%  대응하는 강의노트 : W09_LectureNote.mlx 의 2-3 / 2-4 절
%
%  이 스크립트는 공통 함수(freq_scan, plant_*)를 쓰지 않습니다.
%  MATLAB 기본 명령만으로 적어서, 절마다 따로 떼어 실행할 수 있습니다.
%
%  제어시스템설계 9주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 1. 모델을 돌린다  (강의자료 3쪽)
%  RC 회로 : R = 100 Ohm, C = 0.001 F  ->  tau = R*C = 0.1 s
%  같은 회로에 1 Hz 와 3 Hz 사인을 동시에 넣는다.

R_1 = 100;
C_1 = 0.001;
tau_1 = R_1 * C_1;

A_in = 1;
w1   = 2*pi;        % 1 Hz 를 rad/s 로. Sine Wave 블록은 rad/s 를 받는다
w3   = 6*pi;        % 3 Hz
numG = 1;
denG = [tau_1 1];   % 1 / (0.1s + 1)
t_end = 2;

out_1 = sim('W09_RC_SineCompare', 'StopTime', num2str(t_end));

t_1  = out_1.u1.Time;
u1_1 = out_1.u1.Data;
y1_1 = out_1.y1.Data;
u3_1 = out_1.u3.Data;
y3_1 = out_1.y3.Data;

fprintf('시뮬레이션 완료 : 점 %d 개, 마지막 시각 %.3f s\n', numel(t_1), t_1(end));
fprintf('tau = R*C = %.1f s,  G(s) = 1 / (%.1fs + 1)\n', tau_1, tau_1);

%% 2. 파형에서 크기비와 위상차를 잰다
%  재는 법은 두 줄이다.
%    크기비 = (출력 진폭) / (입력 진폭)     -- 진폭은 (최대 - 최소)/2
%    위상차 = -w * (출력이 0 을 올라가며 지나는 시각 - 입력이 지나는 시각)
%
%  반드시 **정상상태 구간만** 쓴다. 처음 몇 주기는 과도응답이 섞여 있다.
%  tau = 0.1 s 이므로 0.5 s 면 5 tau 가 지나 과도응답은 거의 사라진다.

t_2  = t_1;
tail = t_2 >= 0.5;          % 정상상태로 보는 구간

tt   = t_2(tail);
u1_2 = u1_1(tail);  y1_2 = y1_1(tail);
u3_2 = u3_1(tail);  y3_2 = y3_1(tail);

% --- 진폭 : (최대 - 최소) / 2 ---
amp_u1 = (max(u1_2) - min(u1_2)) / 2;
amp_y1 = (max(y1_2) - min(y1_2)) / 2;
amp_u3 = (max(u3_2) - min(u3_2)) / 2;
amp_y3 = (max(y3_2) - min(y3_2)) / 2;

mag_1Hz_sim = amp_y1 / amp_u1;
mag_3Hz_sim = amp_y3 / amp_u3;

% --- 위상 : 올라가며 0 을 지나는 첫 시각을 둘 다 찾아 뺀다 ---
%     부호가 - 에서 + 로 바뀌는 자리를 찾고, 그 사이를 직선으로 이어 시각을 읽는다
cross_up = @(t, x) deal_cross(t, x);

t_u1 = cross_up(tt, u1_2);
t_y1 = cross_up(tt, y1_2);
t_u3 = cross_up(tt, u3_2);
t_y3 = cross_up(tt, y3_2);

ph_1Hz_sim = -w1 * (t_y1 - t_u1) * 180/pi;
ph_3Hz_sim = -w3 * (t_y3 - t_u3) * 180/pi;

fprintf('\n1 Hz : 입력 진폭 %.4f, 출력 진폭 %.4f  ->  크기비 %.4f\n', ...
        amp_u1, amp_y1, mag_1Hz_sim);
fprintf('       입력이 0 을 지나는 시각 %.4f s, 출력 %.4f s  ->  위상 %.1f 도\n', ...
        t_u1, t_y1, ph_1Hz_sim);
fprintf('3 Hz : 입력 진폭 %.4f, 출력 진폭 %.4f  ->  크기비 %.4f\n', ...
        amp_u3, amp_y3, mag_3Hz_sim);
fprintf('       입력이 0 을 지나는 시각 %.4f s, 출력 %.4f s  ->  위상 %.1f 도\n', ...
        t_u3, t_y3, ph_3Hz_sim);

% 파형 그림
subplot(2,1,1);
plot(tt, u1_2, 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2); hold on;
plot(tt, y1_2, 'b', 'LineWidth', 1.8);
yline( mag_1Hz_sim, 'k:'); yline(-mag_1Hz_sim, 'k:');
grid on; legend('입력 1 Hz', '출력', 'Location', 'southeast');
title(sprintf('1 Hz : 크기 %.3f, 위상 %.0f 도', mag_1Hz_sim, ph_1Hz_sim));
xlabel('시간 [s]'); ylabel('신호');

subplot(2,1,2);
plot(tt, u3_2, 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2); hold on;
plot(tt, y3_2, 'r', 'LineWidth', 1.8);
yline( mag_3Hz_sim, 'k:'); yline(-mag_3Hz_sim, 'k:');
grid on; legend('입력 3 Hz', '출력', 'Location', 'southeast');
title(sprintf('3 Hz : 크기 %.3f, 위상 %.0f 도', mag_3Hz_sim, ph_3Hz_sim));
xlabel('시간 [s]'); ylabel('신호');

%% 3. 손계산 · Simulink · bode 를 나란히 놓는다
%  강의자료 3쪽이 적어 놓은 값은 이렇다.
%    1 Hz : 크기 0.847, 위상 -32 도
%    3 Hz : 크기 0.469, 위상 -62 도

tau_3 = 0.1;
w_3   = [2*pi; 6*pi];

% --- 손계산 : s 자리에 jw 를 넣는다 ---
%     G(jw) = 1 / (1 + j*tau*w) 이므로
%       크기 = 1 / sqrt(1 + (tau*w)^2),  위상 = -atan(tau*w)
mag_hand = 1 ./ sqrt(1 + (tau_3 * w_3).^2);
ph_hand  = -atan(tau_3 * w_3) * 180/pi;

% --- bode 로 얻은 값 ---
G_3 = tf(1, [tau_3 1]);
[m_b, p_b] = bode(G_3, w_3);
mag_bode = squeeze(m_b);
ph_bode  = squeeze(p_b);

% --- 2절에서 Simulink 로 잰 값 ---
mag_sim = [mag_1Hz_sim; mag_3Hz_sim];
ph_sim  = [ph_1Hz_sim;  ph_3Hz_sim];

주파수 = ["1 Hz"; "3 Hz"];
강의자료_크기 = [0.847; 0.469];
강의자료_위상 = [-32; -62];

T_mag = table(주파수, 강의자료_크기, mag_hand, mag_sim, mag_bode);
T_ph  = table(주파수, 강의자료_위상, ph_hand,  ph_sim,  ph_bode);

disp(' ');
disp('크기 — 강의자료 · 손계산 · Simulink · bode');
disp(T_mag);
disp('위상 [도] — 강의자료 · 손계산 · Simulink · bode');
disp(T_ph);

mag_err = max(abs(mag_sim - mag_hand));
ph_err  = max(abs(ph_sim  - ph_hand));
fprintf('Simulink 와 손계산의 최대 차이 : 크기 %.2e, 위상 %.3f 도\n', mag_err, ph_err);

%% 4. 이번 실습의 정리
%  - 같은 회로인데 넣는 주파수가 다르면 답이 다르다. 그것이 주파수응답이다
%  - 1 Hz 에서는 0.847 배로 거의 그대로 통과하고 32 도 늦는다
%  - 3 Hz 에서는 0.469 배로 절반 이하가 되고 62 도 늦는다
%  - 주파수가 올라갈수록 작아지고 더 늦는다. RC 회로는 저역통과 필터다
%  - Sine Wave 블록의 Frequency 는 Hz 가 아니라 rad/s 다. 1 Hz 는 2*pi 다
%  - 처음 몇 주기는 과도응답이라 버린다. tau = 0.1 s 이므로 0.5 s 뒤를 썼다
%  - 손계산 · Simulink 측정 · bode 세 값이 모두 같다 (3절의 차이 참고)

%% 보조 — 올라가며 0 을 지나는 첫 시각
%  (파일 맨 끝의 지역 함수. 두 줄짜리라 절마다 되풀이하지 않고 한 번만 적었다)
function tc = deal_cross(t, x)
    k = find(x(1:end-1) < 0 & x(2:end) >= 0, 1, 'first');
    tc = t(k) + (0 - x(k)) * (t(k+1) - t(k)) / (x(k+1) - x(k));
end
