%% W10_04_gm_pm_build.m
%  10주차 실습 (4) : 교수자 강의자료 06_FrequencyResponse 29~43쪽의 예제
%
%  이 스크립트에서 답할 질문
%    Q1. 왜 하필 크기 1, 위상 -180 도가 불안정 조건인가?       -> 1절
%    Q2. 보드 선도에서 GM 과 PM 을 어떤 순서로 읽는가?         -> 2절
%    Q3. K = 0.5 / 2 / 3 에서 세 가지 그림이 같은 말을 하는가?  -> 3절
%
%  대응하는 강의노트 : W10_LectureNote.mlx 의 1절 / 3-2절 / 3-3절
%
%  이 스크립트는 공통 함수(dg_*, plant_*)를 쓰지 않습니다.
%  MATLAB 기본 명령만으로 적어서, 절마다 따로 떼어 실행할 수 있습니다.
%
%  오늘의 플랜트는 강의자료와 같은 것 하나뿐입니다.
%    G(s) = 1 / ( s * (s+1)^2 )
%
%  제어시스템설계 10주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 1. 왜 크기 1, 위상 -180 도인가  (강의자료 29~30쪽)
%  폐루프는 T = L/(1+L) 이다. L = -1 이면 분모가 0 이 되어 T 가 무한대가 된다.
%  -1 은 두 군데서 온다 : 위상 -180 도(뒤집힘)와 합산점의 빼기.
%  둘을 곱하면 +1 이므로, 돌아온 신호가 원래 신호와 "같은 부호로" 더해진다.

% (1) 분모가 0 에 가까워지면 T 가 치솟는다
L_near = [-0.9; -0.99; -0.999; -1.001];   % -1 에 점점 가까이
T_near = L_near ./ (1 + L_near);          % T = L/(1+L)
table(L_near, T_near)

% (2) 그 L = -1 이 실제로 어느 주파수에서 일어나는가
s   = tf('s');
G_1 = 1/(s*(s+1)^2);

w_cg = 1;                                 % 위상이 -180 도가 되는 주파수 [rad/s]
Gj   = freqresp(G_1, w_cg);
mag_G1   = abs(Gj)                        % |G(j1)| = 0.5
phase_G1 = rad2deg(angle(Gj))             % -180 도

% (3) K 를 세 개 놓고 "한 바퀴 돌아온 신호의 진폭" 을 본다
K_1    = [0.5; 2; 3];
amp_1  = K_1 * mag_G1;                    % |L(j1)| = K * 0.5
verdict = strings(3,1);
for i = 1:3
    if amp_1(i) < 1
        verdict(i) = "줄어든다 (안정)";
    elseif amp_1(i) == 1
        verdict(i) = "그대로다 (지속진동)";
    else
        verdict(i) = "커진다 (불안정)";
    end
end
table(K_1, amp_1, verdict)

% (4) 폐루프 극점 실수부로 같은 결론을 확인한다
maxRe_1 = zeros(3,1);
for i = 1:3
    maxRe_1(i) = max(real(pole(feedback(K_1(i)*G_1, 1))));
end
stable_1 = maxRe_1 < 0;
table(K_1, amp_1, maxRe_1, stable_1)

% (5) 그림 : 왼쪽은 T 가 치솟는 것, 오른쪽은 한 바퀴 돌아온 신호
figure('Name','1절: 왜 -1 인가', 'Position', [60 60 980 380]);

subplot(1,2,1);
L_sweep = linspace(-2.4, -0.02, 1200);
plot(L_sweep, abs(L_sweep./(1+L_sweep)), 'LineWidth', 2); hold on; grid on;
xline(-1, 'r--', 'LineWidth', 1.6);
ylim([0 12]);
xlabel('실수축 위의 L'); ylabel('|T| = |L/(1+L)|');
title('L = -1 에서 폐루프 이득이 치솟는다');

subplot(1,2,2);
t_1 = (0:0.01:12)';
e_in  = sin(w_cg*t_1);                    % 들어간 신호
back  = -amp_1(2) * sin(w_cg*t_1);        % 위상 -180 도를 지난 결과 (K=2)
after = -back;                            % 합산점의 빼기를 한 번 더
plot(t_1, e_in,  'k',  'LineWidth', 3);   hold on; grid on;
plot(t_1, back,  '-',  'LineWidth', 2);
plot(t_1, after, ':',  'LineWidth', 2.5);
xlabel('시간 [s]'); ylabel('신호');
legend('① 들어간 신호 e', '② 위상 -180 도를 지난 것', ...
       '③ 합산점의 빼기까지', 'Location', 'southeast');
title('③ 이 ① 과 겹친다 : (-1)x(-1) = +1');

%% 2. 보드 선도에서 여유를 작도하는 세 걸음  (강의자료 31~37, 41~42쪽)
%  걸음 ① K 를 키우면 크기 곡선만 통째로 올라간다. 위상은 안 움직인다.
%  걸음 ② 위상이 -180 도인 주파수를 "아래 칸" 에서 찾아 "위 칸" 을 읽는다 -> GM
%  걸음 ③ 크기가 0 dB 인 주파수를 "위 칸" 에서 찾아 "아래 칸" 을 읽는다 -> PM

s   = tf('s');
G_2 = 1/(s*(s+1)^2);
K_2 = [0.5; 2];                           % 안정 한계 아래와 그 자리

% 걸음 ① — 두 곡선의 간격이 20*log10(2/0.5) = 12.04 dB 인지
gap_dB = 20*log10(K_2(2)/K_2(1))

% 걸음 ②③ — margin 이 돌려주는 네 숫자
gm_dB_2 = zeros(2,1);  pm_2 = zeros(2,1);
wcg_2   = zeros(2,1);  wcp_2 = zeros(2,1);
for i = 1:2
    [g, p, wg, wp] = margin(K_2(i)*G_2);
    gm_dB_2(i) = 20*log10(g);             % 이득여유 [dB]
    pm_2(i)    = p;                       % 위상여유 [도]
    wcg_2(i)   = wg;                      % 위상이 -180 도인 주파수
    wcp_2(i)   = wp;                       % 크기가 0 dB 인 주파수
end
table(K_2, gm_dB_2, pm_2, wcg_2, wcp_2)

% 위상교차주파수 wcg 가 K 와 무관한지 — 두 값이 같아야 한다
wcg_spread = max(wcg_2) - min(wcg_2)

% 이득여유는 "K 를 몇 배 더 키울 수 있는가" 와 같은 말이다
[gm_half, ~] = margin(0.5*G_2);
K_limit = 0.5 * gm_half                   % 0.5 * 4 = 2 가 나와야 한다

% 그림 : 네 칸을 ① -> ② -> ③ 순서로 본다
w_2 = logspace(-1.3, 1.2, 900);
mag_base = squeeze(abs(freqresp(G_2, w_2)));
ph_base  = rad2deg(unwrap(angle(squeeze(freqresp(G_2, w_2)))));

figure('Name','2절: 여유 작도 세 걸음', 'Position', [60 60 980 620]);

subplot(2,2,1);                           % ① 크기 : 통째로 올라간다
semilogx(w_2, 20*log10(K_2(1)*mag_base), 'LineWidth', 2); hold on; grid on;
semilogx(w_2, 20*log10(K_2(2)*mag_base), 'LineWidth', 2);
yline(0, 'k--', 'LineWidth', 1.4);
xline(wcg_2(1), 'k:');
plot([wcg_2(1) wcg_2(1)], [-gm_dB_2(1) 0], 'r-', 'LineWidth', 4);
ylim([-45 25]);
xlabel('\omega [rad/s]'); ylabel('|KG| [dB]');
legend('K = 0.5', 'K = 2', 'Location', 'southwest');
title(sprintf('① 간격 %.2f dB. 빨간 선이 GM', gap_dB));

subplot(2,2,3);                           % ① 위상 : 안 움직인다
semilogx(w_2, ph_base, 'LineWidth', 4); hold on; grid on;
semilogx(w_2, ph_base, 'LineWidth', 1.6);
yline(-180, 'r--', 'LineWidth', 1.4);
xline(wcg_2(1), 'k:');
xlabel('\omega [rad/s]'); ylabel('\angle KG [도]');
legend('K = 0.5', 'K = 2', 'Location', 'southwest');
title('① 위상은 두 곡선이 완전히 겹친다');

subplot(2,2,2);                           % ③ 0 dB 교차점을 위 칸에서 찾는다
semilogx(w_2, 20*log10(K_2(1)*mag_base), 'LineWidth', 2); hold on; grid on;
yline(0, 'k--', 'LineWidth', 1.4);
plot(wcp_2(1), 0, 'o', 'MarkerSize', 10, 'LineWidth', 2);
xline(wcp_2(1), 'k:');
ylim([-45 25]);
xlabel('\omega [rad/s]'); ylabel('|KG| [dB]');
title(sprintf('③ \\omega_{cp} = %.2f 을 위 칸에서 찾는다', wcp_2(1)));

subplot(2,2,4);                           % ③ 그 주파수의 아래 칸을 읽는다
semilogx(w_2, ph_base, 'LineWidth', 2); hold on; grid on;
yline(-180, 'r--', 'LineWidth', 1.4);
xline(wcp_2(1), 'k:');
ph_at_wcp = interp1(w_2, ph_base, wcp_2(1));
plot([wcp_2(1) wcp_2(1)], [-180 ph_at_wcp], 'r-', 'LineWidth', 4);
xlabel('\omega [rad/s]'); ylabel('\angle KG [도]');
title(sprintf('③ 남은 각 %.1f 도가 PM', pm_2(1)));

%% 3. 이득 세 개로 안정 한계를 통과한다  (강의자료 33~36, 43쪽)
%  나이퀴스트 선도 / 여유 / 계단응답 세 가지가 전부 같은 이야기를 한다.
%    K = 0.5  -1 점의 오른쪽   GM, PM 양수   안착
%    K = 2    -1 점을 통과     GM, PM 영     지속진동
%    K = 3    -1 점의 왼쪽     GM, PM 음수   발산

s   = tf('s');
G_3 = 1/(s*(s+1)^2);
K_3 = [0.5; 2; 3];

gm_dB_3 = zeros(3,1);  pm_3 = zeros(3,1);  maxRe_3 = zeros(3,1);
for i = 1:3
    L = K_3(i) * G_3;
    [g, p] = margin(L);
    gm_dB_3(i) = 20*log10(g);
    pm_3(i)    = p;
    maxRe_3(i) = max(real(pole(feedback(L, 1))));
end
table(K_3, gm_dB_3, pm_3, maxRe_3)

% 여유의 부호와 극점 실수부의 부호가 같이 움직인다
sign_margin = sign(pm_3);
sign_pole   = -sign(round(maxRe_3, 10));  % 좌반면이면 +1. 10 자리에서 끊어
                                          % K = 2 의 4e-16 을 0 으로 읽는다
table(K_3, sign_margin, sign_pole)

% 지속진동의 주파수는 위상교차주파수다 -> 주기를 미리 알 수 있다
[~, ~, wcg_3, ~] = margin(K_3(2)*G_3);
period_pred = 2*pi/wcg_3                  % 약 6.28 s

figure('Name','3절: K = 0.5 / 2 / 3', 'Position', [60 60 1020 380]);

subplot(1,3,1);                           % 나이퀴스트
hold on; grid on;
for i = 1:3
    w_n  = logspace(-1, 2, 2000);
    Ln   = squeeze(freqresp(K_3(i)*G_3, w_n));
    plot(real(Ln), imag(Ln), 'LineWidth', 2);
end
plot(-1, 0, 'rp', 'MarkerSize', 16, 'MarkerFaceColor', 'r');
xlim([-3 0.5]); ylim([-2 0.5]);
xlabel('실수부'); ylabel('허수부');
legend('K = 0.5', 'K = 2', 'K = 3', 'Location', 'southwest');
title('빨간 별이 -1 점');

subplot(1,3,2);                           % 여유
bar([gm_dB_3 pm_3]); grid on;
set(gca, 'XTickLabel', {'K = 0.5', 'K = 2', 'K = 3'});
ylabel('여유');
legend('이득여유 [dB]', '위상여유 [도]', 'Location', 'northeast');
title('K = 2 에서 둘 다 0');

subplot(1,3,3);                           % 계단응답
t_3 = (0:0.02:30)';
hold on; grid on;
for i = 1:3
    plot(t_3, step(feedback(K_3(i)*G_3, 1), t_3), 'LineWidth', 2);
end
yline(1, 'k--');
ylim([-1 3]);
xlabel('시간 [s]'); ylabel('출력');
legend('K = 0.5', 'K = 2', 'K = 3', 'Location', 'northwest');
title(sprintf('노란 진동의 주기 %.2f s', period_pred));

%% 4. 이번 실습의 정리
%  - 불안정 조건은 |L| = 1 이면서 각 L = -180 도. 그때 T 의 분모가 0 이 된다
%  - -1 은 두 군데서 온다 (위상 뒤집힘 + 합산점의 빼기). 곱하면 +1 이다
%  - K 를 키우면 크기 선도만 평행이동하고 위상 선도는 전혀 안 움직인다
%  - 그래서 위상교차주파수 wcg 는 K 와 무관하고,
%    이득여유는 "K 를 몇 배 더 키울 수 있는가" 와 같은 말이 된다
%  - 여유의 부호와 폐루프 극점 실수부의 부호는 항상 같이 움직인다
%  - 지속진동의 주파수는 wcg 다. 현장에서 떨림 주기를 보고 역추적할 수 있다
